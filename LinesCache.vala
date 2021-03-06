// Copyright 2017 Elias Aebi
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

namespace Xi {

class LinesCache {
	private GenericArray<Line?> lines;
	private int invalid_before;
	private int invalid_after;
	private Pango.Context context;
	private Pango.FontDescription font_description;

	public LinesCache(Pango.Context context, Pango.FontDescription font_description) {
		this.lines = new GenericArray<Line?>();
		this.context = context;
		this.font_description = font_description;
	}

	private static void add_invalid(GenericArray<Line?> lines, ref int invalid_before, ref int invalid_after, int n) {
		if (lines.length == 0) {
			invalid_before += n;
		} else {
			invalid_after += n;
		}
	}

	private static void add_line(GenericArray<Line?> lines, ref int invalid_before, ref int invalid_after, Line? line) {
		if (line != null) {
			for (int i = 0; i < invalid_after; i++) {
				lines.add(null);
			}
			invalid_after = 0;
			lines.add(line);
		} else {
			add_invalid(lines, ref invalid_before, ref invalid_after, 1);
		}
	}

	public void update(Json.Object update) {
		var ops = update.get_array_member("ops");
		var new_lines = new GenericArray<Line?>();
		int new_invalid_before = 0;
		int new_invalid_after = 0;
		int index = 0;
		for (int i = 0; i < ops.get_length(); i++) {
			var op = ops.get_object_element(i);
			switch (op.get_string_member("op")) {
				case "copy":
					int n = (int)op.get_int_member("n");
					if (index < invalid_before) {
						int invalid = int.min(n, invalid_before - index);
						add_invalid(new_lines, ref new_invalid_before, ref new_invalid_after, invalid);
						n -= invalid;
						index += invalid;
					}
					while (n > 0 && index < invalid_before + lines.length) {
						add_line(new_lines, ref new_invalid_before, ref new_invalid_after, lines[index-invalid_before]);
						n--;
						index++;
					}
					add_invalid(new_lines, ref new_invalid_before, ref new_invalid_after, n);
					index += n;
					break;
				case "skip":
					int n = (int)op.get_int_member("n");
					index += n;
					break;
				case "invalidate":
					int n = (int)op.get_int_member("n");
					add_invalid(new_lines, ref new_invalid_before, ref new_invalid_after, n);
					break;
				case "ins":
					var json_lines = op.get_array_member("lines");
					for (int j = 0; j < json_lines.get_length(); j++) {
						var json_line = json_lines.get_object_element(j);
						var text = json_line.get_string_member("text");
						var line = new Line(context, text, font_description);
						if (json_line.has_member("cursor")) {
							line.set_cursors(json_line.get_array_member("cursor"));
						}
						if (json_line.has_member("styles")) {
							line.set_styles(json_line.get_array_member("styles"));
						}
						add_line(new_lines, ref new_invalid_before, ref new_invalid_after, line);
					}
					break;
				case "update":
					stdout.printf("op: update\n");
					var json_lines = op.get_array_member("lines");
					for (int j = 0; j < json_lines.get_length(); j++) {
						var json_line = json_lines.get_object_element(j);
						var line = lines[index-invalid_before];
						if (json_line.has_member("cursor")) {
							line.set_cursors(json_line.get_array_member("cursor"));
						}
						if (json_line.has_member("styles")) {
							line.set_styles(json_line.get_array_member("styles"));
						}
						add_line(new_lines, ref new_invalid_before, ref new_invalid_after, line);
						index++;
					}
					break;
			}
		}
		lines = new_lines;
		invalid_before = new_invalid_before;
		invalid_after = new_invalid_after;
	}

	public int get_height() {
		return invalid_before + lines.length + invalid_after;
	}

	public Line? get_line(int index) {
		if (index < invalid_before || index >= invalid_before + lines.length) {
			return null;
		}
		return lines[index - invalid_before];
	}
}

}
