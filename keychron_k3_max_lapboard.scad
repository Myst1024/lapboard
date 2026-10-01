// Keychron K3 Max lapboard
// Units: millimeters
//
// The Keychron K3 Max footprint is approximately 306.7 x 116.7 mm.
// Confirm the dimensions of the specific keyboard before printing.

$fn = 48;

// Board
board_width = 600;
board_depth = 230;
board_thickness = 20;
corner_radius = 5;
top_fillet_radius = 3;

// Print one section at a time: 0 = all-parts preview, 1 = left, 2 = center, 3 = right.
// Each section is nominally 200 mm wide and 230 mm deep.
part_to_render = 0; // [0:3]
part_count = 3;
zigzag_amplitude = 5;
zigzag_step = 20;

// Stiffening rods run left-to-right through all printed board sections.
threaded_rod_diameter = 6.35; // 1/4 inch
threaded_rod_diameter_clearance = 0.8;
threaded_rod_edge_clearance = 6.5;
hex_nut_across_flats = 11.1; // 1/4 inch hex nut, nominal 7/16 inch AF
hex_nut_press_fit_interference = 0.1;
hex_nut_pocket_depth = 5.8;
socket_access_diameter = 17;
socket_access_depth = 12;

// Keyboard recess: keyboard dimensions plus fit clearance on every side.
keyboard_width = 306.7;
keyboard_depth = 116.7;
keyboard_clearance = 1;
keyboard_front_recess_depth = 7;
keyboard_rear_recess_depth = 13;
recess_corner_radius = 5;

// Placement
left_margin = 10;
top_margin = 15;

// Mouse surface begins after this gap from the keyboard pocket.
mouse_gap = 15;

keyboard_pocket_width = keyboard_width + 2 * keyboard_clearance;
keyboard_pocket_depth = keyboard_depth + 2 * keyboard_clearance;
keyboard_pocket_x = left_margin;
keyboard_pocket_y = board_depth - keyboard_pocket_depth - top_margin;
mouse_area_x = keyboard_pocket_x + keyboard_pocket_width + mouse_gap;
mouse_area_width = board_width - mouse_area_x - left_margin;
threaded_rod_hole_diameter = threaded_rod_diameter + threaded_rod_diameter_clearance;
threaded_rod_radius = threaded_rod_hole_diameter / 2;
bottom_threaded_rod_y = threaded_rod_radius + threaded_rod_edge_clearance;
top_threaded_rod_y = board_depth - bottom_threaded_rod_y;

module rounded_rectangle(width, depth, radius) {
    hull() {
        for (x = [radius, width - radius])
            for (y = [radius, depth - radius])
                translate([x, y])
                    circle(r = radius);
    }
}

module board_shape() {
    union() {
        linear_extrude(height = board_thickness - top_fillet_radius)
            rounded_rectangle(board_width, board_depth, corner_radius);

        minkowski() {
            translate([0, 0, board_thickness - top_fillet_radius - 0.01])
                linear_extrude(height = 0.01)
                    offset(delta = -top_fillet_radius)
                        rounded_rectangle(board_width, board_depth, corner_radius);
            sphere(r = top_fillet_radius);
        }
    }
}

module keyboard_pocket() {
    // The wedge floor is one continuous plane, shallow at the front and
    // deeper at the rear to match the keyboard's angled underside.
    translate([keyboard_pocket_x, keyboard_pocket_y])
        intersection() {
            linear_extrude(height = board_thickness + 0.1)
                rounded_rectangle(
                    keyboard_pocket_width,
                    keyboard_pocket_depth,
                    recess_corner_radius
                );
            polyhedron(
                points = [
                    [0, 0, board_thickness - keyboard_front_recess_depth],
                    [keyboard_pocket_width, 0, board_thickness - keyboard_front_recess_depth],
                    [keyboard_pocket_width, keyboard_pocket_depth, board_thickness - keyboard_rear_recess_depth],
                    [0, keyboard_pocket_depth, board_thickness - keyboard_rear_recess_depth],
                    [0, 0, board_thickness + 0.1],
                    [keyboard_pocket_width, 0, board_thickness + 0.1],
                    [keyboard_pocket_width, keyboard_pocket_depth, board_thickness + 0.1],
                    [0, keyboard_pocket_depth, board_thickness + 0.1]
                ],
                faces = [
                    [0, 3, 2, 1], [4, 5, 6, 7], [0, 1, 5, 4],
                    [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]
                ]
            );
        }
}

module threaded_rod_channels() {
    for (channel_y = [bottom_threaded_rod_y, top_threaded_rod_y])
        translate([-0.1, channel_y, board_thickness / 2])
            rotate([0, 90, 0])
                cylinder(h = board_width + 0.2, d = threaded_rod_hole_diameter);
}

module left_nut_pockets() {
    for (channel_y = [bottom_threaded_rod_y, top_threaded_rod_y])
        translate([-0.1, channel_y, board_thickness / 2])
            rotate([0, 90, 0])
                cylinder(
                    h = hex_nut_pocket_depth + 0.1,
                    r = (hex_nut_across_flats - hex_nut_press_fit_interference) / sqrt(3),
                    $fn = 6
                );
}

module right_socket_counterbores() {
    for (channel_y = [bottom_threaded_rod_y, top_threaded_rod_y])
        translate([board_width - socket_access_depth, channel_y, board_thickness / 2])
            rotate([0, 90, 0])
                cylinder(h = socket_access_depth + 0.1, d = socket_access_diameter);
}

module lapboard() {
    // Large flat rectangle with an angled keyboard pocket. The space to the
    // right of the recess is intentionally uninterrupted for a mouse pad.
    difference() {
        board_shape();
        keyboard_pocket();
        threaded_rod_channels();
        left_nut_pockets();
        right_socket_counterbores();
    }
}

function section_width() = board_width / part_count;
function zigzag_x(seam_x, y) =
    seam_x + (floor(y / zigzag_step) % 2 == 0 ? -zigzag_amplitude : zigzag_amplitude);
function seam_points(seam_x) = concat(
    [[zigzag_x(seam_x, 0), 0]],
    [for (index = [1 : floor(board_depth / zigzag_step)])
        [zigzag_x(seam_x, index * zigzag_step), index * zigzag_step]],
    [[zigzag_x(seam_x, board_depth), board_depth]]
);
function reversed(points) = [for (index = [len(points) - 1 : -1 : 0]) points[index]];

module section_mask(part_index) {
    left_seam = seam_points(section_width());
    right_seam = seam_points(2 * section_width());
    mask_margin = zigzag_amplitude + 0.1;

    if (part_index == 0)
        linear_extrude(height = board_thickness + 0.2)
            polygon(points = concat([[-mask_margin, 0]], left_seam,
                                    [[-mask_margin, board_depth]]));
    else if (part_index == 1)
        linear_extrude(height = board_thickness + 0.2)
            polygon(points = concat(left_seam, reversed(right_seam)));
    else if (part_index == 2)
        linear_extrude(height = board_thickness + 0.2)
            polygon(points = concat(right_seam,
                                    [[board_width + mask_margin, board_depth],
                                     [board_width + mask_margin, 0]]));
    else
        assert(false, "part index must be 0, 1, or 2");
}

// The two sawtooth glue faces add surface area while keeping the three pieces
// evenly distributed across the 600 mm board. Export each part separately.
module render_section(part_index) {
    intersection() {
        lapboard();
        translate([0, 0, -0.1])
            section_mask(part_index);
    }
}

if (part_to_render == 0)
    for (part_index = [0 : part_count - 1])
        render_section(part_index);
else
    render_section(part_to_render - 1);

// Preview-only reference outlines. Uncomment in OpenSCAD to inspect layout.
// %translate([mouse_area_x, top_margin, board_thickness])
//     cube([mouse_area_width, board_depth - 2 * top_margin, 0.1]);
