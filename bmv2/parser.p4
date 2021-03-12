
#include "defines.p4"
#include <core.p4>
#include <v1model.p4>


parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata){
                    
    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            TYPE_VLAN: parse_vlan;
            default: accept;

        }
    }
    state parse_vlan {
        packet.extract(hdr.vlan);
        transition select(hdr.ethernet.etherType){
            TYPE_IPV4 : parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl){
            IP_IPHL_TCP : parse_tcp;
            IP_IPHL_UDP : parse_udp;
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
control SwitchDeparser(packet_out packet,
                        in headers hdr){
        apply {
            packet.emit(hdr.ethernet);
            packet.emit(hdr.vlan);
            packet.emit(hdr.ipv4);
            packet.emit(hdr.tcp);
            packet.emit(hdr.udp);
        }

    }

    

    
 