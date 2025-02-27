class IsolatedDevice():
    def __init__(self, name, desc, mac, vlanId, vlanStr) -> None:
        self.name =name
        self.desc = desc
        self.mac = mac
        self.vlanId = vlanId
        self.allowed_destination = []
