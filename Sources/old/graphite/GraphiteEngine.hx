package graphite;

// Port this file to Kha please !

import flash.filters.GlowFilter;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import graphite.io.BinaryLoader;

/**
 * ...
 * @author worldedit
 */

class GraphiteEngine 
{
	public static var configOptions:Dynamic;
	public static var textFormat:TextFormat;
	public static var textFormatLeft:TextFormat;
	
	public static var glowFilter:GlowFilter;
	
	private static var _callback:Void->Void;
	private static var binloader:BinaryLoader;
	
	public static function init(__callback:Void->Void):Void
	{
		_callback = __callback;
		binloader = new BinaryLoader();
		binloader.load("config.gdf", configReady);
	}
	
	static private function configReady() 
	{
		configOptions = GDFParser.parse(binloader.data);
		textFormat = new TextFormat("verdana", 12, configOptions.text_color,null,null,null,null,null,TextFormatAlign.CENTER);
		textFormatLeft = new TextFormat("verdana", 12, configOptions.text_color, null, null, null, null, null, TextFormatAlign.LEFT);
		glowFilter = new GlowFilter(0, 0.7, 10, 10, 1, 5);
		_callback();
	}
	
}