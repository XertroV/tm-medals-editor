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

bool LockTimesAndValidation = false;
uint[] lockedTimes = {0, 0, 0, 0};
bool lockedValidation = false;

void UpdateLockedTimes(CGameCtnChallengeParameters@ params) {
    if (LockTimesAndValidation) {
        lockedTimes[0] = params.AuthorTime;
        lockedTimes[1] = params.GoldTime;
        lockedTimes[2] = params.SilverTime;
        lockedTimes[3] = params.BronzeTime;
    }
}

void SetTimesIfLocked(CGameCtnChallengeParameters@ params) {
    if (LockTimesAndValidation) {
        auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
        editor.PluginMapType.ValidationStatus = CGameEditorPluginMapMapType::EValidationStatus::Validated;
        params.AuthorTime = lockedTimes[0];
        params.GoldTime = lockedTimes[1];
        params.SilverTime = lockedTimes[2];
        params.BronzeTime = lockedTimes[3];
    }
}

uint[] tmpValues = {0, 0, 0, 0};

/** Render function called every frame.
*/
void Render() {
    if (!ShowWindow) return;

    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    bool noEditorAtAll = GetApp().Editor is null;
    if (editor is null && !noEditorAtAll) {
        // we're in a mediatracker editor or something -- *an* editor, not *the* editor. so just hide the window.
        return;
    }
    if (!noEditorAtAll && GetApp().CurrentPlayground !is null) {
        // in validation mode or something, hide
        return;
    }
    if (noEditorAtAll) {
        if (LockTimesAndValidation) {
            // stop watching if we leave all editors
            LockTimesAndValidation = false;
        }
        // hide outside of editor
        return;
    }

    vec2 size = vec2(500, 250);
    vec2 pos = (vec2(Draw::GetWidth(), Draw::GetHeight()) - size) / 2.;
    UI::SetNextWindowSize(int(size.x), int(size.y), UI::Cond::FirstUseEver);
    UI::SetNextWindowPos(int(pos.x), int(pos.y), UI::Cond::FirstUseEver);
    UI::PushStyleColor(UI::Col::FrameBg, vec4(.2, .2, .2, .5));

    if (UI::Begin(MenuTitle, ShowWindow, UI::WindowFlags::None)) {
        UI::AlignTextToFramePadding();

        // just check for any editor here so we don't reset this setting when in mediatracker
        if (GetApp().Editor is null && LockTimesAndValidation) {
            LockTimesAndValidation = false;
        }

        if (UserHasPermissions && editor !is null) {
            UI::Text("Medal Times (ms) \\$888for \\$z" + editor.Challenge.MapName + " \\$888by \\$z" + editor.Challenge.AuthorNickName);
            auto chParams = editor.Challenge.ChallengeParameters;
            auto validated = editor.PluginMapType.ValidationStatus == CGameEditorPluginMapMapType::EValidationStatus::Validated;
            SetTimesIfLocked(chParams);

            bool wasLocked = LockTimesAndValidation;
            LockTimesAndValidation = UI::Checkbox("Lock times and validation status", LockTimesAndValidation);
            AddSimpleTooltip("This will update the validation and medals when changes are made to the map. You can only lock validation 'on'.");

            UI::BeginDisabled(validated || LockTimesAndValidation);
            if (UI::Button("Validate")) {
                editor.PluginMapType.ValidationStatus = CGameEditorPluginMapMapType::EValidationStatus::Validated;
                if (chParams.AuthorTime == 0 || int(chParams.AuthorTime) < 0) {
                    chParams.AuthorTime = 55123;
                }
            }
            UI::EndDisabled();


            if (UI::BeginTable("medals", 2, UI::TableFlags::SizingStretchProp)) {
                UI::BeginDisabled(LockTimesAndValidation);

                UI::TableNextColumn();
                tmpValues[0] = uint(Math::Max(0, UI::InputInt("Author##set-medal", int(chParams.AuthorTime), 100)));
                UI::TableNextColumn();
                UI::Text(Time::Format(chParams.AuthorTime));

                UI::TableNextColumn();
                tmpValues[1] = uint(Math::Max(chParams.AuthorTime, UI::InputInt("Gold##set-medal", int(chParams.GoldTime), 100)));
                UI::TableNextColumn();
                UI::Text(Time::Format(chParams.GoldTime));

                UI::TableNextColumn();
                tmpValues[2] = uint(Math::Max(chParams.GoldTime, UI::InputInt("Silver##set-medal", int(chParams.SilverTime), 100)));
                UI::TableNextColumn();
                UI::Text(Time::Format(chParams.SilverTime));

                UI::TableNextColumn();
                tmpValues[3] = uint(Math::Max(chParams.SilverTime, UI::InputInt("Bronze##set-medal", int(chParams.BronzeTime), 100)));
                UI::TableNextColumn();
                UI::Text(Time::Format(chParams.BronzeTime));

                UI::EndDisabled();

                for (uint i = 1; i < tmpValues.Length; i++) {
                    if (tmpValues[i] < tmpValues[i - 1]) {
                        tmpValues[i] = tmpValues[i - 1] + 1;
                    }
                }
                chParams.BronzeTime = tmpValues[3];
                chParams.SilverTime = tmpValues[2];
                chParams.GoldTime = tmpValues[1];
                chParams.AuthorTime = tmpValues[0];

                if (wasLocked != LockTimesAndValidation) {
                    UpdateLockedTimes(chParams);
                }

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

void AddSimpleTooltip(const string &in msg) {
    if (UI::IsItemHovered()) {
        UI::SetNextWindowSize(250, -1, UI::Cond::Always);
        UI::BeginTooltip();
        UI::TextWrapped(msg);
        UI::EndTooltip();
    }
}
