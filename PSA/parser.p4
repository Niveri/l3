#include "defines.p4"


struct mac_learn_digest_t {
    bit<48>         srcAddr;
    PortId_t        ingress_port;
    bit<12>         vlan_id;
}

struct metadata {
    bool               send_mac_learn_msg;
    mac_learn_digest_t mac_learn_msg;
    bit <16> srcPort;
    bit <16> dstPort;
    clone_i2e_metadata_t clone_meta;
    bit <3> clone_id;
}


parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta)

{   
    InternetChecksum() ck;

    state start {
        transition parse_ethernet;
    }
    
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        verify(hdr.ipv4.ihl==5, error.UnhandledIPv4Options);
        ck.clear();
        ck.add({
            hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.totalLen,
            hdr.ipv4.id,
            hdr.ipv4.flags,
            hdr.ipv4.offset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            //hdr.ipv4.checksum,
            hdr.ipv4.srcAddr,
            hdr.ipv4.dstAddr
        });
        verify(ck.get() == hdr.ipv4.checksum,
                error.BadIPv4HeaderChecksum);
        
        transition select(hdr.ipv4.protocol){
            6 : parse_tcp;
            17 : parse_udp;
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
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            TYPE_VLAN: parse_vlan;
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

control MyDeparser(packet_out packet,
                    inout headers hdr)
        {
            apply{
                packet.emit(hdr.ethernet);
            packet.emit(hdr.vlan);
            packet.emit(hdr.ipv4);
            packet.emit(hdr.tcp);
            packet.emit(hdr.udp);
            }
        }