//
//  Hyphenator.swift
//  Charlatan
//
//  Created by Sascha Watanabe on 5/12/15.
//  Copyright (c) 2015 Hexagon Star Softworks. All rights reserved.
//

import Foundation;


class NHyph : Hyphenator
{
	// --------------------------------------------------------------------
	// MARK: - Properties
	// --------------------------------------------------------------------
	
	private var _hyphenateSymbol:String = "_";
	private var _minWordLength:Int = 5;
	private var _minLetterCount:Int = 3;
	private var _hyphenateLastWord:Bool = true;
	private var _language:HyphenatorLanguage = .EnglishUS;
	
	private let _marker:Character = ".";
	private var _patterns = [NHyphPattern]();
	private var _exceptions = [String:[Int]]();
	
	private static let _createMaskRegex = NSRegularExpression(pattern: "\\w", options: NSRegularExpressionOptions.allZeros, error: nil);
	
	
	// --------------------------------------------------------------------
	// MARK: - Accessors
	// --------------------------------------------------------------------
	
	var hyphenateSymbol:String
	{
		get { return _hyphenateSymbol; }
		set (value) { _hyphenateSymbol = value; }
	}
	
	var minWordLength:Int
	{
		get { return _minWordLength; }
		set (value) { _minWordLength = value >= 0 ? value : 0; }
	}
	
	var minLetterCount:Int
	{
		get { return _minLetterCount; }
		set (value) { _minLetterCount = value >= 0 ? value : 0; }
	}
	
	var hyphenateLastWord:Bool
	{
		get { return _hyphenateLastWord; }
		set (value) { _hyphenateLastWord = value; }
	}
	
	var language:HyphenatorLanguage
	{
		get { return _language; }
		set (value)
		{
			if (value != _language)
			{
				_language = value;
				loadPatterns();
			}
		}
	}
	
	
	// --------------------------------------------------------------------
	// MARK: - Initializers
	// --------------------------------------------------------------------
	
	init()
	{
		loadPatterns();
	}
	
	
	// --------------------------------------------------------------------
	// MARK: - Public Methods
	// --------------------------------------------------------------------
	
	func hyphenate(text:String) -> [[String]]
	{
		var t = text;
		
		if (!_hyphenateLastWord)
		{
			let lastWord:String? = findLastWord(t);
			if let lw = lastWord
			{
				t = t.subString(t.length - lw.length, end: t.length);
				t = hyphenateWordsInText(t) + lw;
				return splitWords(t);
			}
		}
		
		t = hyphenateWordsInText(t);
		//Log.debug(t);
		return splitWords(t);
	}
	
	
	// --------------------------------------------------------------------
	// MARK: - Private Methods
	// --------------------------------------------------------------------
	
	private func splitWords(string:String) -> [[String]]
	{
		var chains = [[String]]();
		let words = string.splitAt(" ");
		for word in words
		{
			let a = word.splitAt(_hyphenateSymbol);
			chains.append(a);
		}
		return chains;
	}
	
	
	private func hyphenateWordsInText(text:String) -> String
	{
		var currentWord = "";
		var result = "";
		
		for c in text
		{
			if (c.isLetter)
			{
				currentWord.append(c);
			}
			else
			{
				if (currentWord.length > 0)
				{
					result += hyphenateWord(currentWord);
					currentWord = "";
				}
				result.append(c);
			}
		}
		
		result += hyphenateWord(currentWord);
		return result;
	}
	
	
	private func hyphenateWord(originalWord:String) -> String
	{
		/* Word Validation. */
		if (originalWord.length < _minWordLength)
		{
			return originalWord;
		}
		
		var word = originalWord.lowercaseString;
		var hyphenationMask:[Int]?;
		
		/* Found the word in exceptions list? */
		if (_exceptions.indexForKey(word) != nil)
		{
			hyphenationMask = _exceptions[word];
		}
		/* Else generate hyphenation mask from word pattern levels. */
		else
		{
			var levels:[Int] = generateLevelsForWord(word);
			hyphenationMask = NHyph.createHyphenateMaskFromLevels(levels);
			correctMask(hyphenationMask!);
		}
		
		return hyphenateByMask(originalWord, hyphenationMask: hyphenationMask!);
	}
	
	
	private func generateLevelsForWord(word:String) -> [Int]
	{
		var wordString = "\(_marker)\(word)\(_marker)";
		var levels = [Int](count: wordString.length, repeatedValue: 0);
		
		for (var i = 0; i < wordString.length - 2; ++i)
		{
			var patternIndex = 0;
			for (var count = 1; count <= wordString.length - i; ++count)
			{
				var patternFromWord = NHyphPattern(str: wordString.subString(i, length: count));
				
				if (NHyphPattern.compare(patternFromWord, y: _patterns[patternIndex]) < 0)
				{
					continue;
				}
				
				//(patternIndex, pattern => HyphenatorPattern.compare(pattern, patternFromWord) > 0);
				patternIndex = _patterns.indexOf
				{
					item in
					return NHyphPattern.compare(item, y: patternFromWord) > 0;
				}!;
				
				if (patternIndex == -1) { break; }
				
				let pattern = _patterns[patternIndex];
				if (NHyphPattern.compare(patternFromWord, y: pattern) >= 0)
				{
					let levelsCount = pattern.getLevelsCount() - 1;
					for (var levelIndex = 0; levelIndex < levelsCount; ++levelIndex)
					{
						var level = pattern.getLevelByIndex(levelIndex);
						if (level > levels[i + levelIndex])
						{
							levels[i + levelIndex] = level;
						}
					}
				}
			}
		}
		return levels;
	}
	
	
	private func findLastWord(text:String) -> String?
	{
		var word = "";
		for (var i = text.length - 1; i >= 0; i--)
		{
			if (text.charAt(i).isLetter) { word += "\(text.charAt(i))"; }
			else if (word.length > 0 && word.containsAnyLetter()) { return word.reversed; }
			else { word += "\(text.charAt(i))"; }
		}
		return nil;
	}
	
	
	private func hyphenateByMask(originalWord:String, hyphenationMask:[Int]) -> String
	{
		var result = "";
		for i in 0 ..< originalWord.length
		{
			if (hyphenationMask[i] > 0) { result += _hyphenateSymbol; }
			result += "\(originalWord.charAt(i))";
		}
		return result;
	}
	
	
	private static func createHyphenateMaskFromLevels(levels:[Int]) -> [Int]
	{
		var len = levels.count - 2;
		var hyphenationMask = [Int](count: len, repeatedValue: 0);
		
		for i in 0 ..< len
		{
			if (i != 0 && levels[i + 1] % 2 != 0) { hyphenationMask[i] = 1; }
			else { hyphenationMask[i] = 0; }
		}
		return hyphenationMask;
	}
	
	
	private func correctMask(hyphenationMask:[Int])
	{
		if (hyphenationMask.count > _minLetterCount)
		{
			clearMask(hyphenationMask, index: 0, length: _minLetterCount);
			clearMask(hyphenationMask, index: hyphenationMask.count - _minLetterCount, length: _minLetterCount);
		}
		else
		{
			clearMask(hyphenationMask, index: 0, length: hyphenationMask.count);
		}
	}
	
	
	private func clearMask(var array:[Int], index:Int, length:Int)
	{
		let end = index + length - 1;
		for i in index ... end
		{
			array[i] = 0;
		}
	}
	
	
	// --------------------------------------------------------------------
	// MARK: - Pattern Preparation Methods
	// --------------------------------------------------------------------
	
	private func loadPatterns()
	{
		switch (_language)
		{
			case .EnglishUS:
				let lang = NHyphSetEnglishUS();
				createPatterns(lang.patterns(), exeptionsString: lang.exeptions());
			default:
				Log.error("NHyph: No such language \"\(_language.rawValue)\".");
		}
	}
	
	
	private func createPatterns(patternsString:String, exeptionsString:String)
	{
		let sep = ",";
		let patterns = patternsString.splitAt(sep);
		_patterns = [NHyphPattern]();
		
		for p in patterns
		{
			let hp = createPattern(p);
			_patterns.append(hp);
		}
		
		let exceptions = exeptionsString.splitAt(sep);
		_exceptions = [String:[Int]]();
		
		for e in exceptions
		{
			let key = e.replace("-", replacement: "");
			let val = createHyphenateMaskFromExceptionString(e);
			_exceptions[key] = val;
		}
	}
	
	
	private func createPattern(pattern:String) -> NHyphPattern
	{
		var levels = [Int]();
		var resultStr = "";
		var waitDigit = true;
		
		for c in pattern
		{
			if (c.isDigit)
			{
				levels.append(c.integerValue);
				waitDigit = false;
			}
			else
			{
				if (waitDigit) { levels.append(0); }
				resultStr.append(c);
				waitDigit = true;
			}
		}
		
		if (waitDigit) { levels.append(0); }
		return NHyphPattern(str: resultStr, levels: levels);
	}
	
	
	private func createHyphenateMaskFromExceptionString(s:String) -> [Int]
	{
		var a = [Int]();
		for char in s
		{
			a.append(char == "-" ? 1 : 0);
		}
		return a;
	}
}
