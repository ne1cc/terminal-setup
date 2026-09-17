--- @since 26.1.22
---
--- Render every image preview at the full size of the preview pane.
---
--- Yazi's built-in image previewer only ever downscales (yazi-adapter/src/image.rs,
--- `Image::downscale`), so an image smaller than the pane is drawn at its native
--- size. This previewer scales those up to meet the pane instead.
---
--- Speed matters more than cleverness here, so it does as little as possible:
---
---   * If the image is already at least as large as the pane, Yazi's own fit
---     already fills it. Delegate straight to the built-in previewer — that path
---     is Rust, needs no subprocess, and is backed by Yazi's own precache.
---   * Otherwise the upscaled copy is written into Yazi's preview cache and the
---     matching preloader builds it ahead of the cursor, so by the time you hover
---     a file the work is usually already done and the preview is just a read.
---
--- Adapted from yazi-rs/plugins:zoom (MIT).

local M = {}

-- Yazi's `preview.image_filter` names mapped onto ImageMagick's.
local FILTERS = {
	nearest = "Point",
	triangle = "Triangle",
	["catmull-rom"] = "Catrom",
	gaussian = "Gaussian",
	lanczos3 = "Lanczos",
}

-- Only plain values survive the sync boundary, so unpack the Rect into a table
-- rather than handing back the userdata itself.
local preview_area = ya.sync(function()
	local a = ui.area("preview")
	return { w = a.w, h = a.h }
end)

-- Pixel size of the preview pane, capped by `preview.max_width`/`max_height`.
-- Those caps are why images looked small before: they bound the whole pipeline,
-- so they have to be at least as large as the pane in physical pixels.
local function canvas(area)
	local cw, ch = rt.term.cell_size()
	if not cw or not area then
		return rt.preview.max_width, rt.preview.max_height
	end

	return math.max(1, math.min(rt.preview.max_width, math.floor(area.w * cw))),
		math.max(1, math.min(rt.preview.max_height, math.floor(area.h * ch)))
end

-- Cache slot for this file at this pane width. Keying on the width means a
-- resized pane re-renders instead of showing a stale, wrongly-sized copy.
local function cache_of(job, w) return ya.file_cache { file = job.file, skip = w } end

local function upscale(src, dest, w, h)
	-- JPEG on purpose, measured as the fastest option at these pixel counts
	-- (0.78s vs 1.32s for WEBP), and it decodes faster on the way back out too.
	-- It also has no alpha channel, which is what the iTerm2 adapter checks to
	-- decide between its fast JPEG path and a slow PNG one. Transparency is
	-- flattened to black explicitly rather than left to chance.
	-- stylua: ignore
	local output, err = Command("magick"):arg {
		tostring(src),
		"-auto-orient", "-strip",
		"-filter", FILTERS[rt.preview.image_filter] or "Triangle",
		"-resize", string.format("%dx%d", w, h),
		"-background", "black", "-alpha", "remove", "-alpha", "off",
		"-quality", rt.preview.image_quality,
		string.format("JPEG:%s", dest),
	}:output()

	if not output then
		return Err("Failed to start `magick`: %s", err)
	elseif not output.status.success then
		return Err("`magick` exited with code %s: %s", output.status.code, output.stderr)
	end
end

function M:peek(job)
	local info = ya.image_info(job.file.url)
	if not info then
		return require("image"):peek(job)
	end

	local w, h = canvas(job.area)
	local cache = cache_of(job, w)

	-- Already big enough for Yazi to fill the pane on its own, or nowhere to
	-- cache an upscale: nothing here beats the built-in path.
	if info.w >= w or info.h >= h or not cache then
		return require("image"):peek(job)
	end

	if not fs.cha(cache) then
		local start = os.clock()
		local err = upscale(job.file.url, cache, w, h)
		if err then
			return ya.preview_widget(job, ui.Text(tostring(err)):area(job.area):wrap(ui.Wrap.YES))
		end
		-- Only debounce when work actually happened, so cache hits stay instant.
		ya.sleep(math.max(0, rt.preview.image_delay / 1000 + start - os.clock()))
	end

	local _, err = ya.image_show(cache, job.area)
	ya.preview_widget(job, err)
end

function M:seek() end

-- Build the upscaled copy ahead of the cursor. This is what makes hovering feel
-- instant: the ImageMagick pass happens while you're still on another file.
function M:preload(job)
	local info = ya.image_info(job.file.url)
	if not info then
		return require("image"):preload(job)
	end

	local w, h = canvas(preview_area())
	local cache = cache_of(job, w)
	if info.w >= w or info.h >= h or not cache then
		return require("image"):preload(job)
	elseif fs.cha(cache) then
		return true
	end

	return upscale(job.file.url, cache, w, h) == nil
end

function M:spot(job) return require("image"):spot(job) end

function M:spot_base(job) return require("image"):spot_base(job) end

return M
