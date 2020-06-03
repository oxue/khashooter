package game.dialogue;

import kha.Color;
import refraction.display.ResourceFormat;
import kha.Framebuffer;
import helpers.DebugLogger;
import yaml.Parser;
import yaml.Yaml;
import kha.Assets;

/**
 * assuming this class is correct
 * @author qwerber
 */
class DialogueManager {
	private var rootDir:String;
	private var dialogues:Map<String, Dialogue>;
	private var currentDialogue:String;
	private var currentPhrase:Int;
	private var playing:Bool;

	public function new(_rootDir:String) {
		this.rootDir = _rootDir;
		this.dialogues = new Map<String, Dialogue>();
		currentDialogue = null;
		playing = false;
		currentPhrase = 0;
	}

	public function playDialogue(dialogueName:String):Void {
		currentDialogue = dialogueName;
		currentPhrase = 0;
		playing = true;
		DebugLogger.info("DEBUG", {dia: currentDialogue});
		DebugLogger.info("DEBUG", {play: playing});
	}

	private function stopDialogue():Void {
		currentDialogue = null;
		currentPhrase = 0;
		playing = false;
	}

	public function advanceDialogue():Void {
		if (!playing) {
			return;
		}
		currentPhrase += 1;
		if (currentPhrase >= dialogues
			.get(currentDialogue)
			.phrases.length
		) {
			stopDialogue();
		}
	}

	public function render(f:Framebuffer) {
		if (!playing) {
			return;
		}
		if (!dialogues.exists(currentDialogue)) {
			return;
		}
		var dialogue = dialogues.get(currentDialogue);

		var phrase = dialogue.phrases[currentPhrase];

		f.g2.color = 0xffaaaaaa;
		f.g2.fillRect(280, 280, 168, 168);
		f.g2.color = Color.White;
		f.g2.drawScaledImage(ResourceFormat.images.get(phrase.portrait), 300, 300, 128, 128);
		f.g2.color = 0xffaaaaaa;
		f.g2.fillRect(448, 280, 600, 168);
		f.g2.color = Color.Black;
		trace(phrase.phrase);
		f.g2.font = Assets.fonts.monaco;
		f.g2.drawString(phrase.phrase, 468, 300);
	}

	public function loadDialogue(dialogueName:String):Void {
		Assets.loadBlobFromPath('${rootDir}/${dialogueName}.yaml', (blob) -> {
			dialogues.set(dialogueName,
				new Dialogue(Yaml.parse(blob.toString(), Parser
					.options()
					.useObjects()
				)));

			DebugLogger.info("DEBUG", dialogues);
		});
	}
}
