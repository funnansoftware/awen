pragma Singleton
import QtQml

// The command vocabulary: every record name posted or handled goes through
// these constants, so qmllint catches a typo at either site.
QtObject {
    readonly property string steer: "steer"
    readonly property string throttle: "throttle"
}
