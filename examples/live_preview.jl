using FrameCapture
using ImageView

# --- Window to capture ---
const window_title = "FlightGear" # TODO:

# --- Start capture ---
start_capture(window_title)

# Capture the first frame to get size
w, h = capture_frame(window_title, "frame_temp.png");
w == 0 && error("Failed to capture first frame.")

# --- Initialize the Makie window ---
gui = imshow_gui((800, 800), (1, 1))  # 1 image slot
canvases = gui["canvas"];

# Show the first captured image
frame_data = get_img(window_title);
imshow(canvases, frame_data);
show(gui["window"]);

# --- Main loop ---
for i = 1:1000
    frame_data = get_img(window_title)
    frame_data !== nothing && imshow(canvases, frame_data)
    sleep(1/80)  # ~80 FPS
end

# --- Stop capture ---
stop_capture(window_title)
println("Capture stopped.")
delete!(canvases)