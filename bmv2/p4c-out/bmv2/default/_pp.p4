#include <core.p4>
#include <v1model.p4>

header ethernet_h {
    bit<48> mac_dstAddr;
    bit<48> mac_srcAddr;
    bit<16> etherType;
}

header vlan_h {
    bit<3>  pcp;
    bit<1>  cfi;
    bit<12> vid;
    bit<16> etherType;
}

header ipv4_h {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> id;
    bit<3>  flags;
    bit<13> offset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> checksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header tcp_h {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNum;
    bit<32> actNum;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgPtr;
}

header udp_h {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length;
    bit<16> checksum;
}

struct headers {
    ethernet_h ethernet;
    vlan_h     vlan;
    ipv4_h     ipv4;
    tcp_h      tcp;
    udp_h      udp;
}

struct int_metadata {
    bit<4>  mcast_grp;
    bit<4>  egress_if;
    bit<16> mcast_hash;
    bit<32> lf_field_list;
}

struct metadata {
    bit<16> srcPort;
    bit<16> dstPort;
}

typedef bit<48> macAddr_t;
typedef bit<12> vlan_id;
parser MyParser(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x800: parse_ipv4;
            0x8100: parse_vlan;
            default: accept;
        }
    }
    state parse_vlan {
        packet.extract(hdr.vlan);
        transition select(hdr.ethernet.etherType) {
            0x800: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            6: parse_tcp;
            17: parse_udp;
            default: accept;
        }
    }
    state parse_tcp {
        packet.extract(hdr.tcp);
        meta.srcPort = hdr.tcp.srcPort;
        meta.dstPort = hdr.tcp.dstPort;
        transition accept;
    }
    state parse_udp {
        packet.extract(hdr.udp);
        meta.srcPort = hdr.udp.srcPort;
        meta.dstPort = hdr.udp.srcPort;
        transition accept;
    }
}

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.vlan);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
    }
}

typedef bit<9> egressSpec_t;
control Switching(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action forward(egressSpec_t port) {
        standard_metadata.egress_spec = port;
    }
    action broadcast() {
        standard_metadata.mcast_grp = 1;
    }
    table switching {
        key = {
            hdr.ethernet.mac_dstAddr: exact;
            hdr.vlan.vid            : exact;
        }
        actions = {
            forward;
            broadcast;
        }
        size = 4000;
    }
    apply {
        switching.apply();
    }
}

struct MacLearnDigest {
    bit<48> srcAddr;
    bit<9>  ingress_port;
    bit<12> vlan_id;
}

control Mac_learning(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action nop() {
    }
    action mac_learn() {
        digest<MacLearnDigest>((bit<32>)1024, { hdr.ethernet.mac_srcAddr, standard_metadata.ingress_port, hdr.vlan.vid });
    }
    table mac_learning {
        key = {
            hdr.ethernet.mac_srcAddr: exact;
        }
        actions = {
            mac_learn;
            nop;
        }
        size = 4000;
    }
    apply {
        mac_learning.apply();
    }
}

control Acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action nop() {
    }
    action drop_acl() {
        mark_to_drop(standard_metadata);
    }
    table acl {
        key = {
            hdr.ipv4.srcAddr : ternary;
            hdr.ipv4.dstAddr : ternary;
            hdr.ipv4.protocol: ternary;
            meta.srcPort     : ternary;
            meta.dstPort     : ternary;
        }
        actions = {
            nop;
            drop_acl;
        }
        size = 1000;
    }
    apply {
        acl.apply();
    }
}

control Routing(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action set_nhop(macAddr_t srcAddr, macAddr_t dstAddr, vlan_id vid) {
        hdr.ethernet.mac_srcAddr = srcAddr;
        hdr.ethernet.mac_dstAddr = dstAddr;
        hdr.vlan.vid = vid;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    action drop() {
        mark_to_drop(standard_metadata);
    }
    table routing {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            set_nhop;
            drop;
        }
        size = 2000;
    }
    apply {
        routing.apply();
    }
}

control Routable(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action route() {
    }
    action nop() {
    }
    table routable {
        key = {
            hdr.ethernet.mac_srcAddr: exact;
            hdr.ethernet.mac_dstAddr: exact;
            hdr.vlan.vid            : exact;
        }
        actions = {
            route;
            nop;
        }
        size = 64;
    }
    apply {
        routable.apply();
    }
}

control VlanEgressProc(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action strip_vlan() {
        hdr.ethernet.etherType = hdr.vlan.etherType;
        hdr.vlan.setInvalid();
    }
    action nop() {
    }
    table VlanEgressProc_t {
        key = {
            standard_metadata.egress_spec: exact;
        }
        actions = {
            strip_vlan;
            nop;
        }
        size = 64;
    }
    apply {
        VlanEgressProc_t.apply();
    }
}

control VlanIngressProc(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action add_vlan() {
        hdr.vlan.setValid();
        hdr.vlan.etherType = hdr.ethernet.etherType;
        hdr.ethernet.etherType = 0x8100;
    }
    action nop() {
    }
    table VlanIngressProc_t {
        key = {
            standard_metadata.ingress_port: exact;
            hdr.vlan.vid                  : exact;
        }
        actions = {
            add_vlan;
            nop;
        }
        size = 64;
    }
    apply {
        VlanIngressProc_t.apply();
    }
}

control MyIngress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    VlanIngressProc() vlanIngressProc;
    Mac_learning() mac_learn;
    Routable() routable;
    Switching() switching;
    Acl() acl;
    Routing() routing;
    apply {
        vlanIngressProc.apply(hdr, meta, standard_metadata);
        mac_learn.apply(hdr, meta, standard_metadata);
        routable.apply(hdr, meta, standard_metadata);
        routing.apply(hdr, meta, standard_metadata);
        switching.apply(hdr, meta, standard_metadata);
        acl.apply(hdr, meta, standard_metadata);
    }
}

control MyEgress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum(hdr.ipv4.isValid(), { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.id, hdr.ipv4.flags, hdr.ipv4.offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.checksum, HashAlgorithm.csum16);
    }
}

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
        verify_checksum(hdr.ipv4.isValid(), { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.id, hdr.ipv4.flags, hdr.ipv4.offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.checksum, HashAlgorithm.csum16);
    }
}

V1Switch(MyParser(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser()) main;

