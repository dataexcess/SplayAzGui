(
//-STEP-1 server stuff

ServerTree.removeAll;

s.options.numOutputBusChannels = 8;

s.waitForBoot({
	~buffers = Dictionary.new;
	~buffers.add(\planets -> PathName("/Users/Dataexcess/Desktop/SO-ON/TOKYO/SAMPLES/PLANETS/").entries.collect({
		arg sf;
		Buffer.readChannel(s, sf.fullPath, channels:[0]);
	})
	);
	~buffers.add(\bees -> PathName("/Users/Dataexcess/Desktop/SO-ON/TOKYO/SAMPLES/BEES/").entries.collect({
		arg sf;
		Buffer.readChannel(s, sf.fullPath, channels:[0]);
	})
	);
	~buffers.add(\drones -> PathName("/Users/Dataexcess/Desktop/SO-ON/TOKYO/SAMPLES/DRONE/").entries.collect({
		arg sf;
		Buffer.readChannel(s, sf.fullPath, channels:[0]);
	})
	);
	~buffers.add(\twists -> PathName("/Users/Dataexcess/Desktop/SO-ON/TOKYO/SAMPLES/TWISTS/").entries.collect({
		arg sf;
		Buffer.readChannel(s, sf.fullPath, channels:[0]);
	})
	);
	~buffers.add(\sharp -> PathName("/Users/Dataexcess/Desktop/SO-ON/TOKYO/SAMPLES/SHARP/").entries.collect({
		arg sf;
		Buffer.readChannel(s, sf.fullPath, channels:[0]);
	})
	);
	~buffers.add(\bea5 -> PathName("/Users/Dataexcess/Desktop/SO-ON/TOKYO/SAMPLES/BEA5/").entries.collect({
		arg sf;
		Buffer.readChannel(s, sf.fullPath, channels:[0]);
	})
	);

	s.sync; //give server time to breath after loading files?
});
)

~testBuf = Buffer.readChannel(s, "/Users/Dataexcess/Desktop/ssaliva_strange.aif", channels:[0]);
~testBuf.play

//test to see if buffers are loaded
~buffers[\planets].choose.play

(
//-STEP-2. create NDef maker function

~nDefMaker_GRAIN = {
	arg name;

	Ndef(name, {
		arg gDens = 20, gMul = 1.0,
		sDur = 1.0, sPos = 0.5, sSpeed = 1.0, sDetune = 0.1,
		pFreq = 2, pPos = 0.0, pSpread = 0.07, pWidth = 2, pDirection = 1, pMix = 0.0, pSource = 0,
		eFreq = 12, eAtt = 0.001, eRel = 0.1, eMix = 0.0,
		fFreq = 60, fQ = 0.8, fDetune = 0.2,
		sFreq = 0,

		buffer = ~testBuf.bufnum.postln,

		amp = 0.0;

		var pointer, detune, sig, env, panMod, pan;

		pointer = LFTri.kr((1/(BufDur.kr(buffer) * sDur)) * sSpeed).range(0.0, sDur);

		detune = LFNoise1.kr(0.2!6).bipolar(sDetune).midiratio;

		sig = GrainBuf.ar(
			1,
			Impulse.ar(gDens),
			(gDens.reciprocal * 2) * gMul,
			buffer,
			sFreq.midiratio + detune, //rate
			sPos + pointer,
			2,
			0.0,
			-1,
			512
		);

		sig = LeakDC.ar(
			BHiPass4.ar(
				sig,
				(fFreq + (LFNoise1.kr(1/10!6).bipolar(fFreq/8) * fDetune)).wrap(20, 18000),
				(fQ + (LFNoise1.kr(1/10!6).bipolar(0.5) * fDetune)).wrap(0.001,1.0)
			)
		);

		panMod = Select.kr(pSource, [LFSaw.kr(pFreq), SinOsc.kr(pFreq), LFNoise1.kr(pFreq)]).range(-1.0,1.0);

		pan = (pPos + (pMix * (panMod * (1 - (2 * pDirection))))).wrap(-1.0,1.0);
		sig = SplayAz.ar(6, sig, pSpread, 1, pWidth, pan);

		SendReply.kr(Impulse.kr(60), ('/' ++ name).asSymbol, [pan, pWidth]);

		env = EnvGen.kr(Env.perc(eAtt, eRel, 1.0, -4), Dust.kr(eFreq));
		sig = (sig * (1 - eMix)) + ((sig * env) * eMix);

		Out.ar(0, sig * amp);
	});

	//Ndef GUI
	Ndef(name).addSpec(\gDens, [1/4, 60, \exp, 0.01].asSpec);
	Ndef(name).addSpec(\gMul, [0.001, 2.0, \lin, 0.00001].asSpec);

	Ndef(name).addSpec(\sPos, [0.0, 1.0, \lin, 0.01].asSpec);
	Ndef(name).addSpec(\sDur, [0.01, 1.0, \lin, 0.01].asSpec);
	Ndef(name).addSpec(\sSpeed, [1/16, 16, \exp, 0.0001].asSpec);
	Ndef(name).addSpec(\sDetune, [0.01, 1.0, \lin, 0.0001].asSpec);
	Ndef(name).addSpec(\sFreq, [-24, 24, \lin, 1].asSpec);

	Ndef(name).addSpec(\pPos, [-1.0, 1.0, \lin, 0.0001].asSpec);
	Ndef(name).addSpec(\pFreq, [1/20, 200, \exp, 0.0001].asSpec);
	Ndef(name).addSpec(\pWidth, [1.0, 6.0, \lin, 0.0001].asSpec);
	Ndef(name).addSpec(\pSpread, [0.0, 1.0, \lin, 0.0001].asSpec);
	Ndef(name).addSpec(\pDirection, [0, 1, \lin, 1].asSpec);
	Ndef(name).addSpec(\pSource, [0, 2, \lin, 1].asSpec);

	Ndef(name).addSpec(\pMix, [0.0, 1.0, \lin, 0.0001].asSpec);

	Ndef(name).addSpec(\eFreq, [1/20, 20, \exp, 0.0001].asSpec);
	Ndef(name).addSpec(\eAtt, [0.0001, 1.0, \exp, 0.0001].asSpec);
	Ndef(name).addSpec(\eRel, [0.07, 2.0, \exp, 0.0001].asSpec);
	Ndef(name).addSpec(\eMix, [0.0, 1.0, \lin, 0.01].asSpec);

	Ndef(name).addSpec(\fFreq, [21, 10000, \exp, 0.0001].asSpec);
	Ndef(name).addSpec(\fQ, [0.15, 0.95, \exp, 0.0001].asSpec);
	Ndef(name).addSpec(\fDetune, [0.0, 1.0, \lin, 0.0001].asSpec);
	Ndef(name).addSpec(\amp, [0.0, 1.0, \lin, 0.0001].asSpec);
}
)

(
//-STEP-3. creature maker function

var pointFromAngleAndDistance,
windowSize = 750, circleSize = 650, dotSize = 20, halfCircleSize = circleSize/2.0;

pointFromAngleAndDistance = {
	arg angle, dist;
	var distance = dist.linlin(1.5,6.0,halfCircleSize-(dotSize/2.0),0);
	(halfCircleSize@halfCircleSize) + ((distance@0).rotate(angle.linlin(-1,1,-pi,pi)).rotate(-pi/2));
};

~creatureMaker = {
	arg name, ndefFunction;
	var dict, audio, visual, callback;

	audio = ndefFunction.(name.asSymbol);
	audio.gui;

	visual = {
		var font, rect;

		font = Font("Monaco", 13);
		rect = name.bounds(font);
		rect = rect.resizeBy(12,8);
		rect.left = rrand(0,400);
		rect.top = rrand(0,400);

		StaticText(~interactionView, rect)
		.background_(Color.gray)
		.align_(\center)
		.stringColor_(Color.white)
		.string_(name)
		.font_(font)
	}.value;

	callback = OSCFunc({
		arg msg;
		var angle = msg[3], distance = msg[4], point;

		if (~animating.asBoolean)
		{
			point = pointFromAngleAndDistance.(angle, distance);
			{
				visual.bounds = Rect(
					point.x - (visual.bounds.width/2),
					point.y - (visual.bounds.height/2),
					visual.bounds.width,
					visual.bounds.height
				);

			}.defer;
		}
	}, ('/' ++ name).asSymbol);

	dict = Dictionary.new;
	dict.put(\audio, audio);
	dict.put(\callback, callback);
	dict.put(\visual, visual);

	~creatures.put(name.asSymbol, dict);
};

~creatureRemover = {
	arg name;
	~creatures[name.asSymbol][\visual].close;
	~creatures[name.asSymbol][\audio].stop;
	~creatures.removeAt(name.asSymbol);
}
)

(
//-STEP-4. GUI maker

~guiMaker = {

	var windowSize, circleSize, halfCircleSize, circleOffset, dotSize, backgroundView, angleText, distanceText, animateToggle, nameText, selectedCreature, clickOffset, angleFromPoint, distanceFromPoint;
	selectedCreature = nil;
	clickOffset = 0@0;
	windowSize = 750;
	circleSize = 650;
	halfCircleSize = circleSize/2.0;
	circleOffset = (windowSize-circleSize)/2.0;
	dotSize = 20;
	angleFromPoint = {arg point; (point - (halfCircleSize@halfCircleSize)).rotate(pi/2).theta.linlin(-pi,pi,-1,1) };
	distanceFromPoint = {arg point; (point - (halfCircleSize@halfCircleSize)).dist(0@0).linlin(0,(halfCircleSize-(dotSize/2)),6.0,1.5) };

	~window = Window.new("PALAIS TOKYO", Rect(20, 20, windowSize, windowSize))
	.front
	.background_(Color.blue);

	backgroundView = UserView(~window, Rect(circleOffset, circleOffset, circleSize, circleSize))
	.background_(Color.blue)
	.drawFunc_({
		arg view;
		var rect = Rect(((view.bounds.width/2)-dotSize),-10,dotSize,dotSize);
		Pen.addOval(Rect(dotSize/2.0, dotSize/2.0, view.bounds.width-dotSize, view.bounds.height-dotSize));
		Color.white.set;
		Pen.stroke;

		Pen.push;
		Pen.translate((view.bounds.width/2),(view.bounds.height/2));
		Pen.fillOval(rect);
		5.do{
			Pen.rotate((1/3)*pi);
			Pen.fillOval(rect);
		};
		Pen.pop;
	});


	nameText = StaticText(~window, Rect(20, 20, 200, 20)).stringColor_(Color.white);
	distanceText = StaticText(~window, Rect(20, 40, 200, 20)).stringColor_(Color.white);
	angleText = StaticText(~window, Rect(20, 60, 200, 20)).stringColor_(Color.white);
	animateToggle = Button(~window, Rect(windowSize - 80, 20, 60, 20))
	.states_([["static",Color.white, Color.blue],["auto",Color.white, Color.blue]])
	.action_({
		arg button;
		~animating = button.value
	});

	~interactionView = UserView(~window, Rect(circleOffset, circleOffset, circleSize, circleSize))
	.mouseDownAction_({ |v, x, y|
		~creatures.values.do { |creature, i|

			if(creature[\visual].bounds.contains(x@y)) {
				selectedCreature = creature;
				clickOffset = Point(x, y) - creature[\visual].bounds.origin;
			}
		}
	})
	.mouseMoveAction_({ |v, x, y|
		if(selectedCreature.notNil) {
			var dist;
			dist = ((x@y) - (halfCircleSize@halfCircleSize)).dist(0@0).linlin(0,(halfCircleSize-(dotSize/2)),0.0,1.0);

			if (dist < 0.994) {
				var creatureRect, angle, distance;
				creatureRect = selectedCreature[\visual].bounds;
				angle = angleFromPoint.(creatureRect.center);
				distance = distanceFromPoint.(creatureRect.center);

				selectedCreature[\visual].bounds = Rect(
					x - clickOffset.x,
					y - clickOffset.y,
					creatureRect.width,
					creatureRect.height
				);
				angleText.string = "angle: " + angle.round(1e-4);
				distanceText.string = "width: " + distance.round(1e-4);
				nameText.string = "moving " + selectedCreature[\visual].string;

				selectedCreature[\audio].set(\pPos, angle);
				selectedCreature[\audio].set(\pWidth, distance);
			};

			~window.refresh;
		}
	})
	.mouseUpAction_({
		if (selectedCreature.notNil) {
			selectedCreature = nil;
		}
	});
}
)

(
var control, device;
//-STEP-5. INITIALISE MIDI
MIDIIn.connect;
device = MIDIIn.findPort("Faderfox UC4","Faderfox UC4");
MIDIIn.connect(0, device);

control = {
	arg src, chan, num, val;

	8.do{
		arg i;
		if (num == (32 + i))
		{
			if (i < ~creatures.values.size)
			{
				~creatures.asSortedArray[i][1][\audio].set(\amp,[0,127].asSpec.unmap(val));
			}
		}
	}
};
MIDIIn.addFuncTo(\control, control);
)

(
//-STEP-5. INITIALISE STUFF

~animating = false;
~creatures.clear;
~creatures = Dictionary.new;
~guiMaker.value
)

~creatureRemover.("G_:::_");

(
//-STEP-6. CREATE CREATURES
var name = "\//_\\/";
~creatureMaker.(name, ~nDefMaker_GRAIN);
~creatures[name.asSymbol][\audio].set(\buffer, ~buffers[\planets][3].bufnum);
)

(
var name = "2_BUF_PLANET_II";
~creatureMaker.(name, ~nDef_maker_PLAYBUF);
~creatures[name.asSymbol][\audio].set(\buffer, ~buffers[\planets][2].bufnum);
)

(
var name = "8]]~___~";
~creatureMaker.(name, ~nDef_maker_BUGR);
)


CmdPeriod.add({
	~creatures.values.do({
		arg creature;
		var window;
		window = creature[\audio].gui;
		"YOOOO".postln;
		window.postln;
		{ window.close }.defer;
		window.close;
	});
	~window.close;
	~creatures.clear;
});


Ndef(\gran2).set(\buffer, ~buffers[\planets][4].bufnum);
Ndef(\gran2).set(\buffer, ~buffers[\planets][1].bufnum);
Scale.lydian.degrees[0]
Scale.lydian.degrees[2]
Scale.lydian.degrees[4]

(
//-STEP-4. create reverb NDef

Ndef(\reverb, {
	arg mix=0.3, room=4, damp=0.5;
	Out.ar(0, FreeVerb.ar(In.ar(0, 2), mix, room, damp));
});

//Ndef GUI
Ndef(\reverb).addSpec(\mix, [0.0, 1.0, \lin, 0.001].asSpec);
Ndef(\reverb).addSpec(\room, [0.5, 20, \exp, 0.0001].asSpec);
Ndef(\reverb).addSpec(\damp, [0.0, 1.0, \lin, 0.001].asSpec);
Ndef(\reverb).gui;
)

s.makeGui //for recording...
BPF Ringz Klank Formant //interesting classes?
{ SinOsc.ar([440, 800]) }.play //test signal