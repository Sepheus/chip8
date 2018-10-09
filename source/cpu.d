module chip8.cpu;

class Cpu {
	import std.stdio;
	import std.file;
	import std.random : uniform;
	private {
		ushort opcode;
		ushort[2048] memory;
		ubyte[16] register;
		ushort index;
		ushort counter;
		ubyte[2048] screen;
		ushort[16] stack;
		ubyte stackPtr;
		ushort keys;
		ubyte timer;
		bool _redraw;
		ubyte[80] font = [ 
			0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
			0x20, 0x60, 0x20, 0x20, 0x70, // 1
			0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
			0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
			0x90, 0x90, 0xF0, 0x10, 0x10, // 4
			0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
			0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
			0xF0, 0x10, 0x20, 0x40, 0x40, // 7
			0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
			0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
			0xF0, 0x90, 0xF0, 0x90, 0x90, // A
			0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
			0xF0, 0x80, 0x80, 0x80, 0xF0, // C
			0xE0, 0x90, 0x90, 0x90, 0xE0, // D
			0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
			0xF0, 0x80, 0xF0, 0x80, 0x80  // F
		];
	}

	this(immutable string rom) {
		if(exists(rom)) { 
			writeln("Loading ROM!");
			counter = 0x100;
			_redraw = false;
			uint size = cast(uint)getSize(rom)/2;
			memory[0x100..0x100+size] = cast(ushort[])read(rom,3584);
		}
		else {
			writeln("Unable to load ROM.");
		}
	}

	@property ubyte[] getScreen() {
		return screen;
	}

	@property bool redraw() {
		return _redraw;
	}

	void cycle() {
		opcode = (memory[counter] & 0xFF) << 8 | memory[counter] >> 8;
		immutable ushort addr = (opcode & 0x0FFF) >> 1;
		immutable ubyte value = opcode & 0xFF;
		immutable ubyte regA = (opcode & 0x0F00) >> 8;
		immutable ubyte regB = (opcode & 0x00F0) >> 4;
		switch(opcode & 0xF000) {
			case 0x0000:
				switch(opcode & 0x00FF) {
					case 0x00E0:
						//CLS
						break;
					case 0x00EE:
						counter = stack[--stackPtr];
						counter--;
						break;
					default:
						writefln("Unknown opcode %x",opcode);
						break;
				}
				break;
			case 0x1000:
				counter = addr;
				counter--;
				break;
			case 0x2000:
				stack[stackPtr++] = counter;
				counter = addr;
				counter--;
				break;
			case 0x3000:
				counter += !(register[regA] ^ value);
				break;
			case 0x4000:
				counter += (register[regA] ^ value) > 0;
				break;
			case 0x5000:
				counter += !(register[regA] ^ register[regB]);
				break;
			case 0x6000:
				register[regA] = value;
				break;
			case 0x7000:
				register[regA] += value;
				break;
			case 0x8000:
				final switch(opcode & 0x000F) {
					case 0x0:
						register[regA] = register[regB];
						break;
					case 0x1:
						register[regA] |= register[regB];
						break;
					case 0x2:
						register[regA] &= register[regB];
						break;
					case 0x3:
						register[regA] ^= register[regB];
						break;
					case 0x4:
						register[0xF] = (register[regA] + register[regB]) >> 8;
						register[regA] += register[regB];
						break;
					case 0x5:
						register[0xF] = register[regA] > register[regB];
						register[regA] -= register[regB];
						break;
					case 0x6:
						register[0xF] = register[regA] & 1;
						register[regA] >>= 1;
						break;
					case 0x7:
						register[0xF] = register[regA] < register[regB];
						register[regA] = cast(ubyte)(register[regB] - register[regA]);
						break;
					case 0xE:
						register[0xF] = register[regA] >> 7;
						register[regA] <<= 1;
						break;
				}
				break;
			case 0x9000:
				counter += (register[regA] ^ register[regB]) > 0;
				break;
			case 0xA000:
				index = addr;
				break;
			case 0xB000:
				counter = addr + register[0];
				counter--;
				break;
			case 0xC000:
				register[regA] = (uniform(0,256) & value);
				break;
			case 0xD000:
				ubyte[] sprite = cast(ubyte[])memory[index..index+8];
				register[0xF] = 0;
				for(ubyte i = 0; i < (opcode & 0x000F); i++) {
					for(ubyte j = 0; j < 8; j--) {
						immutable pixel = (sprite[i] & (0x80 >> j)) >> (7-j);
						immutable offset = ((register[regB] + i) * 64) + register[regA] + j;
						register[0xF] |= screen[offset] & pixel;
						screen[offset] ^= pixel;
					}
				}
				_redraw = true;
				break;
			case 0xE000:
				final switch(opcode & 0x00FF) {
					case 0x9E:
						counter += (keys >> register[regA]) & 1;
						break;
					case 0xA1:
						counter += (keys >> register[regA]) ^ 1;
						break;
				}
				break;
			case 0xF000:
				switch(opcode & 0x00FF) {
					case 0x07:
						register[regA] = timer;
						break;
					case 0x0A:
						//Wait for Key
						break;
					case 0x15:
						timer = register[regA];
						break;
					case 0x18:
						//Sound Timer
						break;
					case 0x1E:
						memory[index] += (register[regA]>>1);
						break;
					default:
						break;
				}
				break;
			default: 
				writefln("Unknown opcode %04X",opcode);
				break;

		}
		timer > 0 ? timer-- : timer;
		writefln("\x1b[2J\x1b[1;1H");
		writefln("Registers: [%(%02X, %)]",register);
		writefln("Executed opcode %04X",opcode);
		counter++;
	}

}