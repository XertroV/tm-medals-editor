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
        LockTimesAndValidation = false;
    }
}

bool LockTimesAndValidation = false;
uint[] lockedTimes = {0, 0, 0, 0};
bool lockedValidation = false;

void UpdateLockedTimes(CGameCtnChallenge@ map) {
    if (LockTimesAndValidation) {
        lockedTimes[0] = map.TMObjective_AuthorTime;
        lockedTimes[1] = map.TMObjective_GoldTime;
        lockedTimes[2] = map.TMObjective_SilverTime;
        lockedTimes[3] = map.TMObjective_BronzeTime;
    }
}

void SetTimesIfLocked(CGameCtnChallenge@ map) {
    if (LockTimesAndValidation) {
        auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
        editor.PluginMapType.ValidationStatus = CGameEditorPluginMapMapType::EValidationStatus::Validated;
        map.TMObjective_AuthorTime = lockedTimes[0];
        map.TMObjective_GoldTime = lockedTimes[1];
        map.TMObjective_SilverTime = lockedTimes[2];
        map.TMObjective_BronzeTime = lockedTimes[3];
    }
}

uint[] tmpValuesPre = {0, 0, 0, 0};
uint[] tmpValues = {0, 0, 0, 0};

bool DoTmpAndPreDiffer() {
    for (uint i = 0; i < tmpValues.Length; i++) {
        if (tmpValues[i] != tmpValuesPre[i]) {
            return true;
        }
    }
    return false;
}

void CopyPreToTmp() {
    for (uint i = 0; i < tmpValuesPre.Length; i++) {
        tmpValues[i] = tmpValuesPre[i];
    }
}

void CopyTmpToPre() {
    for (uint i = 0; i < tmpValues.Length; i++) {
        tmpValuesPre[i] = tmpValues[i];
    }
}

void CheckUpdateTmpFromMap(CGameCtnChallenge@ map) {
    if (tmpValues[0] != map.TMObjective_AuthorTime) {
        tmpValues[0] = map.TMObjective_AuthorTime;
        tmpValues[1] = map.TMObjective_GoldTime;
        tmpValues[2] = map.TMObjective_SilverTime;
        tmpValues[3] = map.TMObjective_BronzeTime;
        CopyTmpToPre();
    }
}

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
            auto map = editor.Challenge;
            UI::Text("Medal Times (ms) \\$888for \\$z" + map.MapName + " \\$888by \\$z" + map.AuthorNickName);
            // auto chParams = map.ChallengeParameters;
            auto validated = editor.PluginMapType.ValidationStatus == CGameEditorPluginMapMapType::EValidationStatus::Validated;
            SetTimesIfLocked(map);

            CheckUpdateTmpFromMap(map);

            bool wasLocked = LockTimesAndValidation;
            LockTimesAndValidation = UI::Checkbox("Lock times and validation status", LockTimesAndValidation);
            AddSimpleTooltip("This will update the validation and medals when changes are made to the map. You can only lock validation 'on'.");

            UI::BeginDisabled(validated || LockTimesAndValidation);
            if (UI::Button("Validate")) {
                editor.PluginMapType.ValidationStatus = CGameEditorPluginMapMapType::EValidationStatus::Validated;
                if (map.TMObjective_AuthorTime == 0 || int(map.TMObjective_AuthorTime) < 0) {
                    map.TMObjective_AuthorTime = 55123;
                    // chParams.AuthorTime = 55123;
                }
            }
            UI::EndDisabled();


            if (UI::BeginTable("medals", 2, UI::TableFlags::SizingStretchProp)) {
                UI::BeginDisabled(LockTimesAndValidation || !validated);

                CopyTmpToPre();

                UI::TableNextColumn();
                tmpValues[0] = uint(Math::Max(0, UI::InputInt("Author##set-medal", int(tmpValues[0]), 100)));
                UI::TableNextColumn();
                UI::Text(Time::Format(map.TMObjective_AuthorTime));

                UI::TableNextColumn();
                tmpValues[1] = uint(Math::Max(tmpValues[0], UI::InputInt("Gold##set-medal", int(tmpValues[1]), 100)));
                UI::TableNextColumn();
                UI::Text(Time::Format(map.TMObjective_GoldTime));

                UI::TableNextColumn();
                tmpValues[2] = uint(Math::Max(tmpValues[1], UI::InputInt("Silver##set-medal", int(tmpValues[2]), 100)));
                UI::TableNextColumn();
                UI::Text(Time::Format(map.TMObjective_SilverTime));

                UI::TableNextColumn();
                tmpValues[3] = uint(Math::Max(tmpValues[2], UI::InputInt("Bronze##set-medal", int(tmpValues[3]), 100)));
                UI::TableNextColumn();
                UI::Text(Time::Format(map.TMObjective_BronzeTime));

                UI::EndDisabled();

                for (uint i = 1; i < tmpValues.Length; i++) {
                    if (tmpValues[i] < tmpValues[i - 1]) {
                        tmpValues[i] = tmpValues[i - 1] + 100;
                    }
                }

                if (validated && DoTmpAndPreDiffer()) {
                    map.TMObjective_AuthorTime = tmpValues[0];
                    map.TMObjective_GoldTime = tmpValues[1];
                    map.TMObjective_SilverTime = tmpValues[2];
                    map.TMObjective_BronzeTime = tmpValues[3];
                }

                if (wasLocked != LockTimesAndValidation) {
                    UpdateLockedTimes(map);
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

    // if we close the window
    if (!ShowWindow) {
        LockTimesAndValidation = false;
    }
}

void AddSimpleTooltip(const string &in msg) {
    if (UI::IsItemHovered()) {
        UI::SetNextWindowSize(250, -1, UI::Cond::Always);
        UI::BeginTooltip();
        UI::TextWrapped(msg);
        UI::EndTooltip();
    }
}
