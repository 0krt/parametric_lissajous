{
	"patcher" : {
		"fileversion" : 1,
		"appversion" : {
			"major" : 8,
			"minor" : 5,
			"revision" : 0,
			"architecture" : "x64",
			"modernui" : 1
		},
		"classnamespace" : "box",
		"rect" : [ 80.0, 80.0, 760.0, 640.0 ],
		"boxes" : [
			{
				"box" : {
					"maxclass" : "newobj",
					"text" : "midiin",
					"id" : "obj-1",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "int" ],
					"patching_rect" : [ 40.0, 40.0, 52.0, 22.0 ]
				}
			},
			{
				"box" : {
					"maxclass" : "newobj",
					"text" : "midiparse",
					"id" : "obj-2",
					"numinlets" : 1,
					"numoutlets" : 7,
					"outlettype" : [ "", "", "", "int", "int", "int", "int" ],
					"patching_rect" : [ 40.0, 90.0, 220.0, 22.0 ]
				}
			},
			{
				"box" : {
					"maxclass" : "newobj",
					"text" : "prepend note",
					"id" : "obj-3",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 40.0, 140.0, 90.0, 22.0 ]
				}
			},
			{
				"box" : {
					"maxclass" : "newobj",
					"text" : "prepend cc",
					"id" : "obj-4",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 150.0, 140.0, 80.0, 22.0 ]
				}
			},
			{
				"box" : {
					"maxclass" : "jweb",
					"id" : "obj-5",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "", "" ],
					"patching_rect" : [ 40.0, 190.0, 680.0, 420.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 0.0, 0.0, 680.0, 420.0 ],
					"url" : "lissajous-m4l.html"
				}
			},
			{
				"box" : {
					"maxclass" : "newobj",
					"text" : "plugout~ 1 2",
					"id" : "obj-6",
					"numinlets" : 2,
					"numoutlets" : 0,
					"patching_rect" : [ 560.0, 140.0, 90.0, 22.0 ]
				}
			},
			{
				"box" : {
					"maxclass" : "comment",
					"id" : "obj-7",
					"numinlets" : 1,
					"numoutlets" : 0,
					"text" : "Lissajous instrument. MIDI -> midiparse -> jweb. Audio plays via system output (enable it in the UI). Freeze the device to embed the HTML.",
					"patching_rect" : [ 280.0, 60.0, 440.0, 60.0 ]
				}
			}
		],
		"lines" : [
			{ "patchline" : { "source" : [ "obj-1", 0 ], "destination" : [ "obj-2", 0 ] } },
			{ "patchline" : { "source" : [ "obj-2", 0 ], "destination" : [ "obj-3", 0 ] } },
			{ "patchline" : { "source" : [ "obj-2", 2 ], "destination" : [ "obj-4", 0 ] } },
			{ "patchline" : { "source" : [ "obj-3", 0 ], "destination" : [ "obj-5", 0 ] } },
			{ "patchline" : { "source" : [ "obj-4", 0 ], "destination" : [ "obj-5", 0 ] } }
		]
	}
}
