// Keychron K3 Max lapboard
// Units: millimeters
//
// The Keychron K3 Max footprint is approximately 306 x 116 mm.
// Confirm the dimensions of the specific keyboard before printing.

/* [Hidden] */
$fn = 48;

/* [Print Sections] */

render_target = "board"; // [board:Board, caps:Caps]
// Use 0 to render every section, or a positive section number to render one at a time for printing.
board_segment_to_render = 0;
// Number of segments to cut the board into
board_segment_count = 3;
// determines how coarse/fine the cut profiles are
vertical_zigzag_count = 5;

/* [Board] */

board_width = 600;
board_height = 230;
board_thickness = 20;
corner_radius = 5;
// Small fillet around entire top of the board
top_fillet_radius = 3;
// Space between left side of keyboard recess and board edge
left_margin = 10;
// Space between keyboard and top of board
top_margin = 15;

/* [Keyboard Recess] */

// Width of the keyboard + some clearance
keyboard_recess_width = 308;
// Height of the keyboard + some clearance
keyboard_recess_height = 118;
// Depth of the front of the keyboard chassis
keyboard_front_recess_depth = 8;
// Depth of the rear of the keyboard chassis
keyboard_rear_recess_depth = 13;
keyboard_recess_corner_radius = 5;

/* [Hardware] */

// Fits 1/4 in threaded rods by default
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

keyboard_recess_x = left_margin;
keyboard_recess_y = board_height - keyboard_recess_height - top_margin;
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
    translate([keyboard_recess_x, keyboard_recess_y])
        intersection() {
            linear_extrude(height = board_thickness + 0.1)
                rounded_rectangle(
                    keyboard_recess_width,
                    keyboard_recess_height,
                    keyboard_recess_corner_radius
                );
            polyhedron(
                points = [
                    [0, 0, board_thickness - keyboard_front_recess_depth],
                    [keyboard_recess_width, 0, board_thickness - keyboard_front_recess_depth],
                    [keyboard_recess_width, keyboard_recess_height,
                     board_thickness - keyboard_rear_recess_depth],
                    [0, keyboard_recess_height,
                     board_thickness - keyboard_rear_recess_depth],
                    [0, 0, board_thickness + 0.1],
                    [keyboard_recess_width, 0, board_thickness + 0.1],
                    [keyboard_recess_width, keyboard_recess_height, board_thickness + 0.1],
                    [0, keyboard_recess_height, board_thickness + 0.1]
                ],
                faces = [
                    [0, 3, 2, 1], [4, 5, 6, 7], [0, 1, 5, 4],
                    [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]
                ]
            );
        }
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
    cap_width = hex_nut_recess_width - plug_size_reduction;
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
    cap_diameter = socket_access_diameter - plug_size_reduction;
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
        threaded_rod_channels();
        left_nut_recesses();
        right_socket_counterbores();
    }
}

function section_width() = board_width / board_segment_count;
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
        for (part_index = [0 : board_segment_count - 1])
            render_section(part_index);
    else
        render_section(board_segment_to_render - 1);
}

if (render_target == "board")
    render_board();
else if (render_target == "caps") {
    left_hex_cap();
    translate([socket_access_diameter, 0, 0])
        right_round_cap();
}
else
    assert(false, "render_target must be board or caps");

