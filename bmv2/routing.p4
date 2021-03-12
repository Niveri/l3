

#include "defines.p4"

control Routing (inout headers hdr,
                inout metadata meta){

        action set_nhop(macAddr_t srcAddr, macAddr_t dstAddr,vlan_id vid){
                hdr.ethernet.srcAddr = srcAddr;
                hdr.ethernet.dstAddr = dstAddr;
                hdr.vlan.vid = vid;
                hdr.ipv4.ttl = hdr.ipv4.ttl -1;

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
