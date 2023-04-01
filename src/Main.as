bool UserHasPermissions = false;

void Main() {
    UserHasPermissions = Permissions::OpenAdvancedMapEditor();
    if (!UserHasPermissions) {
        NotifyError("You lack permissions to use the Advanced Editor -- this plugin will do nothing.");
    }
}

void Notify(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg);
    trace("Notified: " + msg);
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .3, .1, .3), 15000);
}

void NotifyWarning(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
}

const string PluginIcon = Icons::Circle;
const string MenuTitle = "\\$fc0" + PluginIcon + "\\$z " + Meta::ExecutingPlugin().Name;

// show the window immediately upon installation
[Setting hidden]
bool ShowWindow = true;

/** Render function called every frame intended only for menu items in `UI`. */
void RenderMenu() {
    if (UI::MenuItem(MenuTitle, "", ShowWindow)) {
        ShowWindow = !ShowWindow;
    }
}

/** Render function called every frame.
*/
void Render() {
    if (!ShowWindow) return;

    vec2 size = vec2(450, 300);
    vec2 pos = (vec2(Draw::GetWidth(), Draw::GetHeight()) - size) / 2.;
    UI::SetNextWindowSize(int(size.x), int(size.y), UI::Cond::FirstUseEver);
    UI::SetNextWindowPos(int(pos.x), int(pos.y), UI::Cond::FirstUseEver);
    UI::PushStyleColor(UI::Col::FrameBg, vec4(.2, .2, .2, .5));
    if (UI::Begin(MenuTitle, ShowWindow)) {
        UI::AlignTextToFramePadding();
        auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
        if (UserHasPermissions && editor !is null) {
            UI::Text("Medal Times (ms) \\$888for \\$z" + editor.Challenge.MapName + " \\$888by \\$z" + editor.Challenge.AuthorNickName);
            auto chParams = editor.Challenge.ChallengeParameters;
            if (UI::BeginTable("medals", 2, UI::TableFlags::SizingStretchProp)) {

                UI::TableNextColumn();
                chParams.AuthorTime = uint(Math::Max(0, UI::InputInt("Author##set-medal", int(chParams.AuthorTime), 100)));
                UI::TableNextColumn();
                UI::Text(Time::Format(chParams.AuthorTime));
                UI::TableNextColumn();
                chParams.GoldTime = uint(Math::Max(0, UI::InputInt("Gold##set-medal", int(chParams.GoldTime), 100)));
                UI::TableNextColumn();
                UI::Text(Time::Format(chParams.GoldTime));
                UI::TableNextColumn();
                chParams.SilverTime = uint(Math::Max(0, UI::InputInt("Silver##set-medal", int(chParams.SilverTime), 100)));
                UI::TableNextColumn();
                UI::Text(Time::Format(chParams.SilverTime));
                UI::TableNextColumn();
                chParams.BronzeTime = uint(Math::Max(0, UI::InputInt("Bronze##set-medal", int(chParams.BronzeTime), 100)));
                UI::TableNextColumn();
                UI::Text(Time::Format(chParams.BronzeTime));

                UI::EndTable();
            }
        } else if (editor is null) {
            UI::TextWrapped("Open a map in the editor.");
        } else {
            UI::TextWrapped("\\$fe1Sorry, you don't appear to have permissions to use the advanced editor.");
        }
    }
    UI::End();
    UI::PopStyleColor();
}
