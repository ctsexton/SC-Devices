// This program sets up and runs the synthesis in SC.
(
// set up OSC connection to Pd and add listener function
thisProcess.openUDPPort(3001);
~toPd = NetAddr.new("127.0.0.1", 3002);

t = { |msg, time, replyAddr, recvPort|
    if(msg[0] == '/peaks') {
		var index, freq, amp, flag;
		     //   "At time %s received message % from % on port%\n".postf( time, msg[1], replyAddr, recvPort )
		index = msg[1];
		freq = msg[2];
		amp = msg[3];
		flag = msg[4];

		if (amp >= 0.0001) {
			f.setAt(index, freq.cpsmidi);
			a.setAt(index, amp * 2);
		};
		if (amp < 0.0001) {
			f.setAt(index, freq.cpsmidi);
			a.setAt(index, 0);
		}
    }
};
thisProcess.addOSCRecvFunc(t);


// Currently this patch works only with Akai MPK61 keyboards
// TODO: add a GUI to select controller settings

// Setup MIDI functions
~setupMIDInotes = {
	arg uid;
	MIDIdef.noteOn(\harmNoteOn, {
		arg vel, nn, chan, src;
		if (nn > 0) {
		~notes[nn] = Synth.new(\sextone,
			[
				\offset, nn - 60,
				\vel, vel,
				\gate, 1
			], addAction: 'addToHead');
		}
	}, srcID: uid, chan: 0);


	MIDIdef.noteOff(\harmNoteOff, {
		arg vel, nn;
		~notes[nn].set(\gate, 0);
		~notes[nn] = nil;

	}, srcID: uid);
	"MIDI set to UID: ".postln;
	uid.postln;
	};

~dispUID = {
	arg uid;
	uid.postln;
};
MIDIClient.init;
~list = MIDIClient.sources;
~window = Window.new.front;
~window.view.decorator = FlowLayout(~window.view.bounds);
~menu = EZPopUpMenu.new(~window, 500@22, "Menu: ");
~list.do({arg item; ~menu.addItem(item, { MIDIIn.connect(0, item); ~setupMIDInotes.value(item.uid) } )});
~menu.value = 0;

//MIDIIn.connect(0, MIDIIn.findPort("Akai MPK61", "Akai MPK61 MIDI 1"));
//~akai_uid = MIDIIn.findPort("Akai MPK61", "Akai MPK61 MIDI 1").uid;
~notes = Array.newClear(128);
//~midi_src_uid = ~akai_uid;



~synthFunctions = {
	// setup buses for audio and control routing
	a = Bus.control(s, 20);
	f = Bus.control(s, 20);
	//q = Bus.control(s, 20);
	//w = Bus.control(s, 20);
	v = Bus.audio(s, 1);
	~output = {Out.ar(0, v.ar!2)}.play;
	// Add synth defs
	SynthDef("sextone", {
		arg offset, vel, gate;
		var note, dist, env, amp;
		amp = 2;
		env = EnvGen.kr(Env.adsr(0.05, 0.5, 0.5, 0.05, amp), gate, doneAction: 2);
		note = Mix.ar(SinOsc.ar((VarLag.kr((offset + f.kr).midicps, 0.0054)), 0, VarLag.kr(a.kr, 0.0054)));
		dist = note.tanh * env;
		Out.ar(v, dist);
		}).add;
	};
~synthFunctions.value;


s.waitForBoot({ ~synthFunctions.value; "Harmonizer is successfully started".postln; ~toPd.sendMsg("/fromSC", "start") });
)