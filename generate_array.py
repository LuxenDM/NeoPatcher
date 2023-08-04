def generate_cpp_array(input_file, output_file):
    with open(input_file, 'rb') as f:
        binary_data = f.read()
    
    with open(output_file, 'w') as f:
        f.write('#pragma once\n\n')
        f.write('constexpr unsigned char luaScript[] = {\n')
        for byte in binary_data:
            f.write(f'    {byte},\n')
        f.write('};\n')

generate_cpp_array('main.lua', 'lua_index.h')
