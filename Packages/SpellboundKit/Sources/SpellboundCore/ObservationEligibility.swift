/// Unknown controls fail closed. The probe inspects metadata only, even when eligible.
public enum ObservationEligibility {
    public static func permitsRead(
        permissionGranted: Bool,
        appExcluded: Bool,
        monitoringActive: Bool,
        role: String?,
        subrole: String?
    ) -> Bool {
        guard permissionGranted, !appExcluded, monitoringActive else { return false }
        guard subrole != "AXSecureTextField" else { return false }
        // Restrict initial adapters to explicitly recognized standard controls.
        guard subrole == nil || subrole == "AXStandard" else { return false }
        return role == "AXTextField" || role == "AXTextArea"
    }
}
