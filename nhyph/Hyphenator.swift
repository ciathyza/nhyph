//
//  Hyphenator.swift
//  Charlatan
//
//  Created by Sascha Watanabe on 5/19/15.
//  Copyright (c) 2015 Hexagon Star Softworks. All rights reserved.
//

import Foundation;


enum HyphenatorLanguage : String
{
	case EnglishUS = "EnglishUS";
}


protocol Hyphenator
{
	var hyphenateSymbol:String { get set };
	var minWordLength:Int { get set };
	var minLetterCount:Int { get set };
	var hyphenateLastWord:Bool { get set };
	var language:HyphenatorLanguage { get set };


	///
	/// Hyphenates a text and returns an array with sub-arrays of type String. Every word of the text occupies one sub array.
	///
	func hyphenate(text:String) -> [[String]];
}
