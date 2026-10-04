// Keychron K3 Max lapboard
// Units: millimeters
//
// The Keychron K3 Max footprint is approximately 306 x 116 mm.
// Confirm the dimensions of the specific keyboard before printing.

/* [Hidden] */
$fn = 48;

/* [Print Sections] */

render_target = "board"; // [board:Board, caps:Caps, retainer:Keyboard retainer]
// Use 0 to render every section, or a positive section number to render one pre-cut section at a time for printing.
board_segment_to_render = 0;
// Number of segments to cut the board into
board_segment_count = 3;
// determines how coarse the zigzags between cut parts are
vertical_zigzag_count = 5;

/* [Lap Board] */

// 'board width' ÷ 'board segment count' must be smaller than your print bed
board_width = 600;
// Must be smaller than your print bed
board_height = 230;
board_thickness = 20;
corner_radius = 5;
// Small fillet around entire top of the board
top_fillet_radius = 3;

/* [Keyboard] */

// Width of the keyboard + some clearance
keyboard_recess_width = 308;
// Height of the keyboard + some clearance
keyboard_recess_height = 118;
// Depth of the front of the keyboard chassis
keyboard_front_recess_depth = 8;
// Depth of the rear of the keyboard chassis
keyboard_rear_recess_depth = 15;
keyboard_recess_corner_radius = 5;
// Space between left side of keyboard recess and board edge
keyboard_left_margin = 10;
// Space between keyboard and top of board
keyboard_top_margin = 15;

// Add slots at the top and bottom of the keyboard for retention clips
keyboard_retainer_enabled = true;

/* [Hidden] */

// Width of the centered slide channel
keyboard_retainer_channel_width = 20;
// Depth of the slide channel and slider base
keyboard_retainer_channel_depth = 2;
// Width of the chamfer around the channel opening
keyboard_retainer_channel_chamfer = 0.5;
// Clearance on each side of the slider base
keyboard_retainer_slider_clearance = 0.025;
// Length of the slider base within the channel
keyboard_retainer_slider_length = 9;
// Amount that the slider nose reaches into the keyboard opening
keyboard_retainer_tab_depth = 2;
// Height of the finger knob above the slider
keyboard_retainer_knob_height = 1;

/* [Mousepad] */

mousepad_width = 241;
mousepad_height = 201;
mousepad_corner_radius = 6;
// If you don't want a mousepad section just set this to 0
mousepad_recess_depth = 1;
mousepad_right_margin = 10;
mousepad_top_margin = 15;

/* [Hardware] */

// Fits 1//4 in threaded rods by default
threaded_rod_hole_diameter = 7.15;
// Measured flat to flat.
hex_nut_recess_width = 11.5;
hex_nut_recess_depth = 7;
// Needs to be just wide enough to fit the socket for the hex nut
socket_access_diameter = 17.0;
socket_access_depth = 12;

/* [End Caps] */

// Shrink the caps just enough for a snug press fit
plug_size_reduction = 0.10; // [0:0.10:1.00]

/* [Hidden] */

vertical_zigzag_amplitude = board_thickness / (2 * vertical_zigzag_count);

keyboard_recess_x = keyboard_left_margin;
keyboard_recess_y = board_height - keyboard_recess_height - keyboard_top_margin;
mousepad_recess_x = board_width - mousepad_width - mousepad_right_margin;
mousepad_recess_y = board_height - mousepad_height - mousepad_top_margin;
threaded_rod_radius = threaded_rod_hole_diameter / 2;
bottom_threaded_rod_y = 10.075;
top_threaded_rod_y = board_height - bottom_threaded_rod_y;
bottom_threaded_rod_z = board_thickness / 2;
top_threaded_rod_z = board_thickness / 2;

module rounded_rectangle(width, depth, radius) {
    hull() {
        for (x = [radius, width - radius])
            for (y = [radius, depth - radius])
                translate([x, y])
                    circle(r = radius);
    }
}

module board_shape() {
    // Uniform thickness keeps the print face flat and the upper surface level.
    union() {
        linear_extrude(height = board_thickness - top_fillet_radius)
            rounded_rectangle(board_width, board_height, corner_radius);
        minkowski() {
            translate([0, 0, board_thickness - top_fillet_radius - 0.01])
                linear_extrude(height = 0.01)
                    offset(delta = -top_fillet_radius)
                        rounded_rectangle(board_width, board_height, corner_radius);
            sphere(r = top_fillet_radius);
        }
    }
}

module keyboard_recess() {
    // The wedge floor is one continuous plane, shallow at the front and
    // deeper at the rear to match the keyboard's angled underside.
    slope_angle = atan(
        (keyboard_front_recess_depth - keyboard_rear_recess_depth)
        / keyboard_recess_height
    );
    slope_margin = board_thickness + 0.1;

    translate([keyboard_recess_x, keyboard_recess_y])
        intersection() {
            linear_extrude(height = board_thickness + 0.1)
                rounded_rectangle(
                    keyboard_recess_width,
                    keyboard_recess_height,
                    keyboard_recess_corner_radius
                );
            translate([0, 0, board_thickness - keyboard_front_recess_depth])
                rotate([slope_angle, 0, 0])
                    translate([0, -slope_margin, 0])
                        cube([
                            keyboard_recess_width,
                            keyboard_recess_height / cos(slope_angle) + 2 * slope_margin,
                            board_thickness + 0.1
                        ]);
        }
}

module mousepad_recess() {
    translate([
        mousepad_recess_x,
        mousepad_recess_y,
        board_thickness - mousepad_recess_depth
    ])
        linear_extrude(height = mousepad_recess_depth + 0.1)
            rounded_rectangle(
                mousepad_width,
                mousepad_height,
                mousepad_corner_radius
            );
}

module tapered_prism(
    center_x,
    start_y,
    length,
    lower_width,
    upper_width,
    lower_z,
    upper_z
) {
    translate([center_x, start_y + length / 2, lower_z])
        linear_extrude(
            height = upper_z - lower_z,
            scale = [upper_width / lower_width, 1]
        )
            square([lower_width, length], center = true);
}

// Narrower upper openings capture the wider lower foot of the slider.
// They end before the board's perimeter fillet, leaving solid travel stops.
module keyboard_retainer_channel() {
    center_x = keyboard_recess_x + keyboard_recess_width / 2;
    recess_center_y = keyboard_recess_y + keyboard_recess_height / 2;
    recess_rear_y = keyboard_recess_y + keyboard_recess_height;
    channel_overlap = 0.2;

    if (keyboard_retainer_enabled)
        union() {
            tapered_prism(
                center_x,
                recess_rear_y - channel_overlap,
                keyboard_top_margin - top_fillet_radius + channel_overlap,
                keyboard_retainer_channel_width
                + 2 * keyboard_retainer_channel_chamfer,
                keyboard_retainer_channel_width,
                board_thickness - keyboard_retainer_channel_depth - 0.01,
                board_thickness + 0.1
            );
            translate([0, 2 * recess_center_y, 0])
                mirror([0, 1, 0])
                    tapered_prism(
                        center_x,
                        recess_rear_y - channel_overlap,
                        keyboard_top_margin - top_fillet_radius + channel_overlap,
                        keyboard_retainer_channel_width
                        + 2 * keyboard_retainer_channel_chamfer,
                        keyboard_retainer_channel_width,
                        board_thickness - keyboard_retainer_channel_depth - 0.01,
                        board_thickness + 0.1
                    );
        }
}

// Model the slider in its forward, keyboard-retaining position.
module keyboard_retainer() {
    center_x = keyboard_recess_x + keyboard_recess_width / 2;
    recess_rear_y = keyboard_recess_y + keyboard_recess_height;
    channel_start_y = recess_rear_y;
    nose_start_y = recess_rear_y - keyboard_retainer_tab_depth;
    slider_top_width = keyboard_retainer_channel_width
        - 2 * keyboard_retainer_slider_clearance;
    slider_bottom_width = keyboard_retainer_channel_width
        + 2 * keyboard_retainer_channel_chamfer
        - 2 * keyboard_retainer_slider_clearance;
    top_z = board_thickness + 0.01;
    bottom_z = board_thickness - keyboard_retainer_channel_depth;
    nose_bottom_z = top_z - 0.1;
    slider_end_y = channel_start_y + keyboard_retainer_slider_length;

    if (keyboard_retainer_enabled)
        union() {
            // One closed mesh avoids CGAL unions between the nose and body.
            polyhedron(
                points = [
                    [
                        center_x - slider_top_width / 2,
                        nose_start_y,
                        nose_bottom_z
                    ],
                    [
                        center_x + slider_top_width / 2,
                        nose_start_y,
                        nose_bottom_z
                    ],
                    [
                        center_x + slider_top_width / 2,
                        nose_start_y,
                        top_z
                    ],
                    [
                        center_x - slider_top_width / 2,
                        nose_start_y,
                        top_z
                    ],
                    [
                        center_x - slider_bottom_width / 2,
                        channel_start_y,
                        bottom_z
                    ],
                    [
                        center_x + slider_bottom_width / 2,
                        channel_start_y,
                        bottom_z
                    ],
                    [
                        center_x + slider_top_width / 2,
                        channel_start_y,
                        top_z
                    ],
                    [
                        center_x - slider_top_width / 2,
                        channel_start_y,
                        top_z
                    ],
                    [
                        center_x - slider_bottom_width / 2,
                        slider_end_y,
                        bottom_z
                    ],
                    [
                        center_x + slider_bottom_width / 2,
                        slider_end_y,
                        bottom_z
                    ],
                    [
                        center_x + slider_top_width / 2,
                        slider_end_y,
                        top_z
                    ],
                    [
                        center_x - slider_top_width / 2,
                        slider_end_y,
                        top_z
                    ]
                ],
                faces = [
                    [0, 1, 2, 3],
                    [0, 4, 5, 1],
                    [1, 5, 6, 2],
                    [2, 6, 7, 3],
                    [3, 7, 4, 0],
                    [4, 8, 9, 5],
                    [5, 9, 10, 6],
                    [6, 10, 11, 7],
                    [7, 11, 8, 4],
                    [8, 11, 10, 9]
                ]
            );
            translate([
                center_x,
                channel_start_y + keyboard_retainer_slider_length - 3,
                board_thickness
            ])
                cylinder(h = keyboard_retainer_knob_height, d = 4);
        }
}

// Render the slider flat with its knob pointing upward.
module render_keyboard_retainer() {
    center_x = keyboard_recess_x + keyboard_recess_width / 2;
    recess_rear_y = keyboard_recess_y + keyboard_recess_height;

    translate([
        -center_x,
        -recess_rear_y + keyboard_retainer_tab_depth,
        -board_thickness + keyboard_retainer_channel_depth
    ])
        keyboard_retainer();
}

module threaded_rod_channels() {
    for (channel = [
        [bottom_threaded_rod_y, bottom_threaded_rod_z],
        [top_threaded_rod_y, top_threaded_rod_z]
    ])
        translate([-0.1, channel[0], channel[1]])
            rotate([0, 90, 0])
                cylinder(h = board_width + 0.2, d = threaded_rod_hole_diameter);
}

module left_nut_recesses() {
    for (channel = [
        [bottom_threaded_rod_y, bottom_threaded_rod_z],
        [top_threaded_rod_y, top_threaded_rod_z]
    ])
        translate([-0.1, channel[0], channel[1]])
            rotate([0, 90, 0])
                cylinder(
                    h = hex_nut_recess_depth + 0.1,
                    r = hex_nut_recess_width / sqrt(3),
                    $fn = 6
                );
}

module right_socket_counterbores() {
    for (channel = [
        [bottom_threaded_rod_y, bottom_threaded_rod_z],
        [top_threaded_rod_y, top_threaded_rod_z]
    ])
        translate([board_width - socket_access_depth, channel[0], channel[1]])
            rotate([0, 90, 0])
                cylinder(h = socket_access_depth + 0.1, d = socket_access_diameter);
}

module left_hex_cap() {
    cap_thickness = 2;
    cap_width = left_hex_cap_width();
    pull_hole_diameter = 2;
    pull_hole_x = cap_width / sqrt(3) - pull_hole_diameter / 2;

    difference() {
        cylinder(h = cap_thickness, r = cap_width / sqrt(3), $fn = 6);
        translate([pull_hole_x, 0, -0.1])
            cylinder(h = cap_thickness + 0.2, d = pull_hole_diameter);
    }
}

module right_round_cap() {
    cap_thickness = 5;
    cap_face_thickness = 1;
    cap_diameter = right_round_cap_diameter();
    pull_hole_diameter = 2;
    pull_hole_offset = cap_diameter / 2 - pull_hole_diameter;

    difference() {
        cylinder(h = cap_thickness, d = cap_diameter);
        translate([0, 0, cap_face_thickness])
            cylinder(
                h = cap_thickness - cap_face_thickness + 0.1,
                d = cap_diameter - 2
            );
        translate([pull_hole_offset, 0, -0.1])
            cylinder(h = cap_face_thickness + 0.2, d = pull_hole_diameter);
    }
}

module lapboard() {
    // Large flat rectangle with an angled keyboard recess. The space to the
    // right of the recess is intentionally uninterrupted for a mouse pad.
    difference() {
        board_shape();
        keyboard_recess();
        mousepad_recess();
        keyboard_retainer_channel();
        threaded_rod_channels();
        left_nut_recesses();
        right_socket_counterbores();
    }
}

function section_width() = board_width / board_segment_count;
function left_hex_cap_width() = hex_nut_recess_width - plug_size_reduction;
function right_round_cap_diameter() = socket_access_diameter - plug_size_reduction;
function vertical_zigzag_x(seam_x, index) = seam_x
    + (index % 2 == 0 ? -vertical_zigzag_amplitude : vertical_zigzag_amplitude);
function vertical_zigzag_points(seam_x, z_min, z_max) = concat(
    [[vertical_zigzag_x(seam_x, 0), z_min]],
    [for (index = [1 : vertical_zigzag_count])
        [vertical_zigzag_x(seam_x, index),
         z_min + index * (z_max - z_min) / vertical_zigzag_count]]
);
function reversed(points) = [for (index = [len(points) - 1 : -1 : 0]) points[index]];

module vertical_zigzag_mask(profile) {
    translate([0, board_height, 0])
        rotate([90, 0, 0])
            linear_extrude(height = board_height)
                polygon(points = profile);
}

module section_mask(part_index) {
    mask_z_min = -0.1;
    mask_z_max = board_thickness + 0.1;
    mask_margin = vertical_zigzag_amplitude + 0.1;
    left_boundary = part_index == 0
        ? [[-mask_margin, mask_z_min], [-mask_margin, mask_z_max]]
        : vertical_zigzag_points(
            part_index * section_width(),
            mask_z_min,
            mask_z_max
        );
    right_boundary = part_index == board_segment_count - 1
        ? [[board_width + mask_margin, mask_z_max],
           [board_width + mask_margin, mask_z_min]]
        : reversed(vertical_zigzag_points(
            (part_index + 1) * section_width(),
            mask_z_min,
            mask_z_max
        ));

    vertical_zigzag_mask(concat(left_boundary, right_boundary));
}

// The two 45-degree sawtooth faces increase glue area without flat overhangs.
module render_section(part_index) {
    intersection() {
        lapboard();
        section_mask(part_index);
    }
}

module render_board() {
    if (board_segment_count < 1 || floor(board_segment_count) != board_segment_count)
        assert(false, "board_segment_count must be a positive integer");
    else if (board_segment_to_render < 0
             || board_segment_to_render > board_segment_count
             || floor(board_segment_to_render) != board_segment_to_render)
        assert(false, "board_segment_to_render must be 0 or a valid segment number");
    else if (board_segment_to_render == 0)
        translate([-board_width / 2, -board_height / 2, 0])
            for (part_index = [0 : board_segment_count - 1])
                render_section(part_index);
    else
        translate([
            -section_width() * (board_segment_to_render - 0.5),
            -board_height / 2,
            0
        ])
            render_section(board_segment_to_render - 1);
}

module render_caps() {
    hex_cap_radius = left_hex_cap_width() / sqrt(3);
    round_cap_radius = right_round_cap_diameter() / 2;
    cap_pair_center_x = (socket_access_diameter + round_cap_radius - hex_cap_radius) / 2;

    translate([-cap_pair_center_x, 0, 0]) {
        left_hex_cap();
        translate([socket_access_diameter, 0, 0])
            right_round_cap();
    }
}

if (render_target == "board")
    render_board();
else if (render_target == "caps")
    render_caps();
else if (render_target == "retainer")
    render_keyboard_retainer();
else
    assert(false, "render_target must be board, caps, or retainer");

