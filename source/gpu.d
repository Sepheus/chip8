module chip8.gpu;

class Gpu {
	import allegro5.allegro;
	import allegro5.allegro_primitives;

	private {
		ALLEGRO_DISPLAY *display = null;
		ALLEGRO_BITMAP *screen = null;
		ALLEGRO_EVENT_QUEUE *event_queue = null;
		ALLEGRO_TIMER *timer = null;
		ALLEGRO_EVENT ev;
		ushort keys;
		ushort[ushort] keyTable;
	}

	this(int width=640, int height=480) {
		al_init();
		al_install_keyboard();
		al_init_primitives_addon();

		display = al_create_display(640, 320);
		screen = al_create_bitmap(64,32);
		timer = al_create_timer(1.0 / 60.0);
		event_queue = al_create_event_queue();

		al_register_event_source(event_queue, al_get_display_event_source(display));
		al_register_event_source(event_queue, al_get_timer_event_source(timer));
		al_register_event_source(event_queue, al_get_keyboard_event_source());

		initKeys();

		al_start_timer(timer);
	}

	void initKeys() {
		keyTable[ALLEGRO_KEY_1] = 0x1;
		keyTable[ALLEGRO_KEY_2] = 0x2;
		keyTable[ALLEGRO_KEY_3] = 0x4;
		keyTable[ALLEGRO_KEY_4] = 0x8;

		keyTable[ALLEGRO_KEY_Q] = 0x10;
		keyTable[ALLEGRO_KEY_W] = 0x20;
		keyTable[ALLEGRO_KEY_E] = 0x40;
		keyTable[ALLEGRO_KEY_R] = 0x80;

		keyTable[ALLEGRO_KEY_A] = 0x100;
		keyTable[ALLEGRO_KEY_S] = 0x200;
		keyTable[ALLEGRO_KEY_D] = 0x400;
		keyTable[ALLEGRO_KEY_F] = 0x800;

		keyTable[ALLEGRO_KEY_Z] = 0x1000;
		keyTable[ALLEGRO_KEY_X] = 0x2000;
		keyTable[ALLEGRO_KEY_C] = 0x4000;
		keyTable[ALLEGRO_KEY_V] = 0x8000;
	}

	bool cycle() {
		al_wait_for_event(event_queue, &ev);
		pollKeys();
		if(ev.type == ALLEGRO_EVENT_TIMER) {
			return true;
		}
		return false;
	}

	@property ushort getKeys() {
		return keys;
	}

	ushort pollKeys() {
		if(ev.type == ALLEGRO_EVENT_KEY_DOWN) {
			keys |= keyTable.get(cast(ushort)ev.keyboard.keycode,0);
		}
		else if(ev.type == ALLEGRO_EVENT_KEY_UP) {
			keys ^= keyTable.get(cast(ushort)ev.keyboard.keycode,0);
		}
		return keys;
	}

	void render(const ubyte[] pixels) {
		al_clear_to_color(al_map_rgb(0,0,0));
		al_set_target_bitmap(screen);
		foreach(i, ref const ubyte pixel; pixels) {
			al_draw_pixel(i % 64, i / 64, al_map_rgb_f(pixel,0,pixel));
		}
		al_set_target_bitmap(al_get_backbuffer(display));
		al_draw_scaled_bitmap(screen,0,0,64,32,0,0,640,320,0);
		al_flip_display();
	}

	~this() {
		al_destroy_bitmap(screen);
		al_destroy_timer(timer);
		al_destroy_display(display);
		al_destroy_event_queue(event_queue);
	}
}