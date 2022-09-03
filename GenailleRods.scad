tunnel_width = 25;
tunnel_height = 9;
tunnel_neck = 9;  // 5
wall_size = 1.5;  // 1.5
digit_shift = tunnel_neck + wall_size;

labels_width = 8;
ceiling_height = 1.5;  // 1.
rod_height = tunnel_height + 2 * ceiling_height;

bottom_overhead = 3;
top_overhead = 12;

rod_width = tunnel_width + labels_width;

echo("rod_width", rod_width);

pin_width = 3;
pin_height = 0.5 * rod_height;
pin_length = 5;

epsilon=0.01;


function min_shift(val) = digit_shift * val;
function max_shift(val) = tunnel_neck + digit_shift * val;


module tunnel(start_min, start_max, end_min, end_max) {    
    linear_extrude(height = tunnel_height)
        polygon([
            [-epsilon, min_shift(start_min)], 
            [-epsilon, max_shift(start_max)], 
            [tunnel_width, max_shift(end_max)], 
            [tunnel_width, min_shift(end_min)]
        ]);
}

module label_tunnel(top, bottom, mul_num) {
    end_min = mul_num - 1 - bottom;
    end_max = mul_num - 1 - top;
        
    translate([tunnel_width - epsilon, min_shift(end_min), 0])
        linear_extrude(height = tunnel_height)
            square([labels_width + 2 * epsilon, max_shift(end_max - end_min)], center=false);
}

module rod_tunnel(left, top, bottom, mul_num) {
    negated_left = mul_num - 1 - left + 1;
    end_min = mul_num - 1 - bottom;
    end_max = mul_num - 1 - top;
    
    tunnel(negated_left, negated_left, end_min, end_max);
}

module digit(n, size, height, halign, valign) {
    linear_extrude(height=height, convexity=4)
        scale([0.8, 1])
            text(
                str(n),
                size=size,
                font="Revamped:style=Regular",
                halign=halign,
                valign=valign
            );
}

module rod_section_negative(rod_num, mul_num){    
    for (k = [ 0 : mul_num - 1 ])
    {
        n = (rod_num * mul_num + k) % 10;
        
        if(k != mul_num)
        {
            translate([
                tunnel_width + 0.5 * labels_width, 
                min_shift(mul_num - 1 - k) + 0.5 * tunnel_neck, 
                tunnel_height - epsilon
            ])
                digit(
                    n, 
                    size=8, 
                    height=ceiling_height + 2. * epsilon, 
                    halign="center",
                    valign="center"
                );
            
            label_tunnel(k, k, mul_num);
        }
        
        if(n == 0 && k > 0)
        {
            top = max(k - 10, 0);
            left = floor((rod_num * mul_num + k) / 10);
                        
            rod_tunnel(left, top, k - 1, mul_num);
        }
    }
        
    top = max(0, (mul_num - 1) - (rod_num * mul_num + mul_num - 1) % 10);
    left = floor((rod_num * mul_num + mul_num - 1) / 10) + 1;
    
    rod_tunnel(left, top, mul_num - 1, mul_num);
}

function sum(values, s=0) = s == len(values) - 1 ? values[s] : values[s] + sum(values,s+1);

module rod_negative(rod_num, muls){
    for (i = [0:len(muls) - 1]){
        shift = i == 0 ? 0 : sum([for (j = [0:i-1]) muls[j]]);
        
        translate([0, min_shift(shift), 0])
            rod_section_negative(rod_num, muls[i]);
    }
}

module rod_without_pins(rod_num, muls) {
    muls_sum = sum(muls);
    
    digit_indent = 0.2 * rod_height;
    echo(top_overhead - wall_size);
    
    difference()
    {
        // %
        linear_extrude(rod_height)
            square(
                [
                    rod_width, 
                    min_shift(muls_sum) + bottom_overhead + wall_size + top_overhead
                ], 
                center=false
            );
        translate([0, bottom_overhead + wall_size, 0])
            union()
            {
                translate([0, 0, ceiling_height])
                    rod_negative(rod_num, muls);
                
                translate([
                    0.5 * rod_width, 
                    min_shift(muls_sum), 
                    rod_height - digit_indent
                ])
                    digit(
                        rod_num, 
                        size=top_overhead - wall_size, 
                        height=digit_indent + epsilon, 
                        halign="center"
                    );
            }
    }
}

module pins(width, height, length, muls_sum, height_epsilon=0)
{
    translate([0, 0, rod_height - height])
        linear_extrude(height + height_epsilon)
        {
            translate([0, 0.8 * bottom_overhead - 0.5 * width])
                square([length, width]);
            
            translate([
                0, 
                bottom_overhead + wall_size + min_shift(muls_sum) + 0.5 * top_overhead - 0.5 * width
            ])
                square([length, width], center=false);
        }
}

module rod(rod_num, muls) {
    muls_sum = sum(muls);
    pin_shift = -0.5;
    
    difference()
    {
        union()
        {
            rod_without_pins(rod_num, muls);
            
            translate([-(pin_length + pin_shift), 0, 0])
                pins(
                    pin_width + 2. * pin_shift, 
                    pin_height + 2. * pin_shift, 
                    pin_length + pin_shift, 
                    muls_sum
                );
                
        }
        translate([rod_width - pin_length, 0, 0])
            pins(pin_width, pin_height, pin_length, muls_sum, height_epsilon=epsilon);
    }
}

// TODO: finish index_rod.
module index_rod(muls) {
    muls_sum = sum(muls);
    
    for (i = [1:len(muls)]){
        shift = i == 0 ? 0 : sum([for (j = [0:i-1]) muls[j]]);
        
        translate([0, bottom_overhead + min_shift(shift), rod_height])
            digit(
                muls[i - 1], 
                size=8, 
                height=2,
                halign="center",
                valign="top"
            );
    }
}


muls = [3];

max_x = 5;
for(x=[0:max_x - 1])
{
    for(y=[0:1])
    {
        i = x + y * max_x;
        translate([x * (rod_width + 0.5), y * 50, 0])
            rod(i, muls);
    }
}

*translate([3 * (rod_width + pin_length), 0, 0])
    index_rod(muls);
