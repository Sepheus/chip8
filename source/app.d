import std.stdio;
import chip8.cpu;
import chip8.gpu;

void main() {
	Cpu chip8 = new Cpu("./roms/pong.rom");
	Gpu gpu = new Gpu();
	bool running = true;

	while(running) {
		if(gpu.cycle()) {
			chip8.cycle();
			writefln("%04X",gpu.getKeys());
			if(chip8.redraw) {
				gpu.render(chip8.getScreen);
			}
		}
	}

	delete gpu;
	delete chip8;
}