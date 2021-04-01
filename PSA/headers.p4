#include <core.p4>
#include "psa.p4"



header ethernet_h{  
        bit<48> dstAddr;
        bit<48> srcAddr;
        bit<16> etherType;
}


header vlan_h{
    bit<3> pcp;  // Priority code point
    bit<1> cfi; //drop eligible indicator (dei)
    bit<12> vid;
    bit<16> etherType;
}


header ipv4_h{
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> totalLen;
    bit<16> id;
    bit<3> flags;
    bit<13> offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> checksum;
    bit<32> srcAddr;
    bit<32> dstAddr;

}


header tcp_h {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNum;
    bit<32> actNum;
    bit<4> dataOffset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgPtr;

}


header udp_h{
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length;
    bit<16> checksum;
}
header clone_i2e_metadata_t {
    bit<8> custom_tag;
    bit<48> srcAddr;
}

struct headers{
    ethernet_h  ethernet;
    vlan_h      vlan;
    ipv4_h      ipv4;
    tcp_h       tcp;
    udp_h       udp;
}