# Experiment 2
# This experiment verifies that MPLS-based micro-segmenting works for isolating commercial-of-the-shelf hardware.
# Here, it is no longer possible to static OpenFlow rules that are encoded in shell-scripts.
# Onboarding procedures for certain products - such as, for example - the TP-Link Kasa Smart Plug HS110 require various devices such as enter and leave the network during setup
# These setup procedures resulting in WPA-session terminate which remove ports from the switch in resulting in OpenFlow rules becoming invalid
# Hence, rules are deleted and static rules in scripts (i.e having all ports as an active) are not applicable.

# To overcome this limitation, the controller pushes only those rules, how apply to the current port configuration of OVS

# For the sake of simplicity, MAC-Address / VLAN combinations are hard-coded in this script
# This - of course - results in some duplication w.r.t. wpa_psk files
# To improve the situation, one could use a share database to generate both files
# However, such software-engineering related improvements are out-of-scope for this expierment.


# This experiment utilizes an SDN-controller to configure the switches

# Note: This script was based on the "simple_switch_13.py" program that is part of ryu.

from ryu.base import app_manager
from ryu.controller import ofp_event
from ryu.controller.handler import CONFIG_DISPATCHER, MAIN_DISPATCHER
from ryu.controller.handler import set_ev_cls
from ryu.ofproto import ofproto_v1_3
from ryu.lib.packet import packet
from ryu.lib.packet import ethernet
from ryu.lib.packet import ether_types
from initial_rules import InitialRulez
from gateway import Gateway

class MPLSIsolation(app_manager.RyuApp):
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]

    def __init__(self, *args, **kwargs):
        super(MPLSIsolation, self).__init__(*args, **kwargs)
        self.vlan_to_switch_port = {}
        self.initial_rules = InitialRulez()


    # Initial connect of the switch
    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)
    def switch_features_handler(self, ev):
        datapath = ev.msg.datapath
        self.initial_rules.push(datapath)
        if (ev.msg.datapath_id == 0x10): # Gateway is APU-10
            Gateway(datapath.ports).push_rules(datapath)


    # Attaching Port due to Request
    @set_ev_cls(ofp_event.EventOFPPortStatus, CONFIG_DISPATCHER)
    def port_status_handler(self, ev):
        pass
        #msg = ev.msg
        #dp = msg.datapath
        #ofp = dp.ofproto
        #portname = msg.desc.name
        #dpid = dp.id
        #if msg.reason == ofp.OFPPR_ADD:
        #    reason = 'ADD'
        #    self.add_flow_for_port(portname,dp)
        #elif msg.reason == ofp.OFPPR_DELETE:
        #    reason = 'DELETE'
        #    self.remove_flows_for_port(portname,dp)
        #elif msg.reason == ofp.OFPPR_MODIFY:
        #    reason = 'MODIFY'
        #else:
        #    reason = 'unknown'
