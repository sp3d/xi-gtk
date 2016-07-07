// Copyright 2016 Elias Aebi
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

class Application: Gtk.Application {
	public Application() {
		Object(application_id: "com.github.eyelash.xi-gtk", flags: ApplicationFlags.HANDLES_OPEN);
	}

	public override void startup() {
		base.startup();
		var core_connection = new CoreConnection({"./xi-core"});
		var window = new Gtk.ApplicationWindow(this);
		window.set_default_size(400, 400);
		window.add(new EditView(core_connection));
		window.show_all();
	}

	public override void activate() {
		
	}

	public override void open(File[] files, string hint) {
		stdout.printf("open\n");
	}

	public static int main(string[] args) {
		var app = new Application();
		return app.run(args);
	}
}

}
