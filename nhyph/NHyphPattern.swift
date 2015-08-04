//
//  HyphenatorPattern.swift
//  Charlatan
//
//  Created by Sascha Watanabe on 5/12/15.
//  Copyright (c) 2015 Hexagon Star Softworks. All rights reserved.
//

import Foundation;


class NHyphPattern
{
	// --------------------------------------------------------------------
	// MARK: - Properties
	// --------------------------------------------------------------------
	
	var str:String;
	var levels:[Int];
	
	
	// --------------------------------------------------------------------
	// MARK: - Initializers
	// --------------------------------------------------------------------
	
	init(str:String, levels:[Int])
	{
		self.str = str;
		self.levels = levels;
	}
	
	
	init(str:String)
	{
		self.str = str;
		levels = [Int]();
	}
	
	// --------------------------------------------------------------------
	// MARK: - Methods
	// --------------------------------------------------------------------
	
	func getLevelByIndex(index:Int) -> Int
	{
		return levels[index];
	}
	
	
	func getLevelsCount() -> Int
	{
		return levels.count;
	}
	
	
	func toString() -> String
	{
		return "[NHyphPattern str=\(str), levels=\(levels)]";
	}
	
	
	static func compare(x:NHyphPattern, y:NHyphPattern) -> Int
	{
		var first:Bool = x.str.length < y.str.length;
		var minSize:Int = first ? x.str.length : y.str.length;
		for (var i = 0; i < minSize; ++i)
		{
			if (x.str.charAt(i) < y.str.charAt(i)) { return -1; }
			if (x.str.charAt(i) > y.str.charAt(i)) { return 1; }
		}
		return first ? -1 : 1;
	}
	
	//int IComparer<Pattern>.Compare(Pattern x, Pattern y)
	//{
	//	return Compare(x, y);
	//}
	
	//public int CompareTo(Pattern other)
	//{
	//	return Compare(this, other);
	//}
}
