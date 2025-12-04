using FrameCapture
using ImageView

const window_title = "FlightGear" # TODO:

start_capture(window_title)

w, h = capture_frame(window_title, "frame_temp.png");
w == 0 && error("Failed to capture first frame.")

gui = imshow_gui((800, 800), (1, 1)) 
canvases = gui["canvas"];

frame_data = get_img(window_title);
imshow(canvases, frame_data);
show(gui["window"]);

for i = 1:1000
    frame_data = get_img(window_title)
    frame_data !== nothing && imshow(canvases, frame_data)
    sleep(1/80)  # ~80 FPS
end

stop_capture(window_title)
println("Capture stopped.")
