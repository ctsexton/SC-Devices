thisProcess.openUDPPort(3001);

(
thisProcess.removeOSCRecvFunc(t);
t = { |msg, time, replyAddr, recvPort|
    if(msg[0] == '/peaks') {
		var index, freq, amp;
		     //   "At time %s received message % from % on port%\n".postf( time, msg[1], replyAddr, recvPort )
		index = msg[1];
		freq = msg[2];
		amp = msg[3];

		if (amp >= 0.00005) {
			f.setAt(index, freq.cpsmidi);
			a.setAt(index, amp * 2);
		};
		if (amp < 0.00005) {
			f.setAt(index, freq.cpsmidi);
			a.setAt(index, 0);
		}
    }
};
thisProcess.addOSCRecvFunc(t);
)
thisProcess.removeOSCRecvFunc(t);

(
b = Buffer.alloc(s, 512, 1, {arg buf; buf.sine1Msg(1.0/[1,2,3,4,5,6,7,8,9,10])});
a = Bus.control(s, 20);
f = Bus.control(s, 20);
v = Bus.audio(s, 1);
)


(
var harmArray = [0, -5, -8, -10, -14, -15];
SynthDef("tracker", {
	var chord, spread, verb, dist, bigArray, detuneArray, delay;

	chord = harmArray.collect( { arg item, i; Mix.ar(RLPF.ar(COsc.ar(b.bufnum, (VarLag.kr((item + f.kr).midicps, 0.012)), 1, VarLag.kr(a.kr, 0.012)), VarLag.kr(In.kr(f, 1).midicps + 500, 1), 0.4))});
	dist = chord.tanh;
	delay = Mix.ar([dist * 0.5, CombL.ar(dist, 0.5, 0.1, 1, 0.1)]);
	spread = Splay.ar(delay, 1);
	verb = FreeVerb2.ar(spread[0], spread[1], 0.33, 0.75);
	Out.ar(0, verb);
}).add;

SynthDef("SINEtracker", {
	var chord, spread, verb, dist, bigArray, detuneArray, delay;

	chord = harmArray.collect( { arg item, i; Mix.ar(SinOsc.ar((VarLag.kr((item + f.kr).midicps, 0.012)), 0, 2 * VarLag.kr(a.kr, 0.012)))});
	dist = chord.tanh;
	delay = Mix.ar([dist, CombL.ar(dist, 0.5, 0.15, 1, 0.2)]);
	spread = Splay.ar(delay, -1);
	verb = FreeVerb2.ar(spread[0], spread[1], 0.2, 0.75);
	Out.ar(0, verb);
}).add;
)

x = Synth.new("tracker");
y = Synth.new("SINEtracker");

x.free;
y.free;


(
MIDIClient.init;
MIDIIn.connect(0, MIDIIn.findPort("Akai MPK61", "Akai MPK61 MIDI 1"));
~akai_uid = MIDIIn.findPort("Akai MPK61", "Akai MPK61 MIDI 1").uid;
)

MIDIClient.disposeClient;

(
~notes = Array.newClear(128);
~midi_src_uid = ~akai_uid;

SynthDef("Collier", {
	arg offset, vel, gate;
	var note, dist, env, amp;
	amp = 2;
	env = EnvGen.kr(Env.adsr(0.005, 0.5, 0.5, 0.01, amp), gate, doneAction: 2);
	note = Mix.ar(SinOsc.ar((VarLag.kr((offset + f.kr).midicps, 0.012)), 0, 2 * VarLag.kr(a.kr, 0.012)));
	dist = note.tanh * env;
	Out.ar(v, dist);
}).add;

SynthDef("Collier2", {
	arg offset, vel, gate;
	var note, dist, env, amp;
	amp = 2;
	env = EnvGen.kr(Env.adsr(0.005, 0.5, 0.5, 0.01, amp), gate, doneAction: 2);
	note = Mix.ar(RLPF.ar(COsc.ar(b.bufnum, (VarLag.kr((offset + f.kr).midicps, 0.012)), 1, VarLag.kr(a.kr, 0.012)), VarLag.kr(In.kr(f, 1).midicps + 500, 1), 0.4));
	dist = note.tanh * env;
	Out.ar(v, dist);
}).add;

~output = {Out.ar(0, v.ar!2)}.play;
)



(
MIDIdef.noteOn(\noteonTest, {
	arg vel, nn, chan, src;
	//[vel, nn].postln;
	~notes[nn] = Synth.new(\Collier,
		[
			\offset, nn - 60,
			\vel, vel,
			\gate, 1
		], addAction: 'addToHead');
}, srcID: ~midi_src_uid);


MIDIdef.noteOff(\noteoffTest, {
	arg vel, nn;
	//[vel, nn].postln;
	~notes[nn].set(\gate, 0);
	//~notes[nn].free;

	~notes[nn] = nil;

}, srcID: ~midi_src_uid);
)

