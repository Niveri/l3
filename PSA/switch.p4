
#include "headers.p4"
#include "parser.p4"

#include "vlan_ingress_processing.p4"
#include "vlan_egress_processing.p4"
#include "acl.p4"
#include "routing.p4"
#include "routable.p4"
#include "switching.p4"


struct empty_metadata_t {
}

error {
    UnhandledIPv4Options,
    BadIPv4HeaderChecksum
}


parser MyIngressParser(packet_in pkt,
                         out headers hdr,
                         inout metadata meta,
                         in psa_ingress_parser_input_metadata_t in_meta,
                         in empty_metadata_t resubmit_meta,
                         in empty_metadata_t recirculate_meta)
        {

        MyParser() pars;
        state start {
            transition packet_in_parsing;
        }
        state packet_in_parsing {
            pars.apply(pkt, hdr, meta);
            transition accept;
        }


}
control MyIngress (inout headers hdr,
                    inout metadata meta,
                    in psa_ingress_input_metadata_t in_meta,
                    inout psa_ingress_output_metadata_t out_meta)
{   

        VlanIngressProc() vlanIngProc;
        Routable() routable;
        Switching() switching;
        Acl() acl;
        action noAction(){}
        action do_clone(CloneSessionId_t session_id){
            out_meta.clone = true;
            out_meta.clone_session_id = session_id;
            meta.clone_id = 1;
        }
        table clone_t{
            key = {
                meta.dstPort : exact;
            }
            actions = {do_clone;}
        }
        action unknown_source(){
            meta.send_mac_learn_msg = true;
            meta.mac_learn_msg.srcAddr = hdr.ethernet.srcAddr;
            meta.mac_learn_msg.ingress_port = in_meta.ingress_port;
            meta.mac_learn_msg.vlan_id = hdr.vlan.vid;

                    }
        table learned_sources {
            key = {
                hdr.ethernet.srcAddr : exact;
            }
            actions = { noAction; unknown_source;}
            default_action = unknown_source();

        }

        action L2_forward (PortId_t e_port){
            send_to_port(out_meta, e_port);
        }
        table l2_tbl {
            key = { hdr.ethernet.dstAddr : exact; }
            actions = { L2_forward; NoAction; }
            default_action = NoAction();
         }

         apply {

            meta.send_mac_learn_msg = false;
            vlanIngProc.apply(hdr, meta, in_meta);
            routable.apply(hdr, meta, out_meta);
        
            switching.apply(hdr, meta, out_meta);
            acl.apply(hdr, meta, out_meta);
            l2_tbl.apply();
            clone_t.apply();
             
         }
}

control MyEgress(inout headers hdr,
                    inout metadata meta,
                    in psa_egress_input_metadata_t in_meta,
                    inout psa_egress_output_metadata_t out_meta)
                    {
                        VlanEgressProc() vlanEgrProc;
                        apply
                        {
                             vlanEgrProc.apply(hdr, meta, in_meta);
                        }
                    }

parser MyEgressParser(packet_in pkt,
                        out headers hdr,
                        inout metadata meta,
                        in psa_egress_parser_input_metadata_t in_meta,
                        in metadata normal_meta,
                        in clone_i2e_metadata_t clone_i2e_meta,
                        in empty_metadata_t clone_e2e_meta)
{
    MyParser() pars;
    state start {
        transition select(in_meta.packet_path){
            PSA_PacketPath_t.CLONE_I2E: copy_clone_i2e_meta;
            PSA_PacketPath_t.NORMAL: packet_in_parsing;
        }
        
    }
    state copy_clone_i2e_meta{
        meta.clone_meta = clone_i2e_meta;
        transition packet_in_parsing;
    }
    state packet_in_parsing {
        pars.apply(pkt, hdr, meta);
        transition accept;
    }

}
control MyIngressDeparser(packet_out packet,
                    out clone_i2e_metadata_t clone_i2e_meta,
                    out empty_metadata_t recirculate_meta,
                    out metadata normal_meta,
                    inout headers hdr,
                    in metadata meta,
                    in psa_ingress_output_metadata_t out_meta
                    )
{   
    
    Digest<mac_learn_digest_t>() mac_learn_digest;
    apply{
        if (psa_clone_i2e(out_meta)){
            clone_i2e_meta.custom_tag = (bit<8>) meta.clone_id;
            if (meta.clone_id ==1){
                clone_i2e_meta.srcAddr = hdr.ethernet.srcAddr;
            }
        }
        mac_learn_digest.pack(meta.mac_learn_msg);  
                  
        
        
        packet.emit(hdr.ethernet);
        packet.emit(hdr.vlan);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
    
        }
}
        
control MyEgressDeparser(packet_out packet,
                    out empty_metadata_t clone_e2e_meta,
                    out empty_metadata_t recirculate_meta,
                    inout headers hdr,
                    in metadata meta,
                    in psa_egress_output_metadata_t in_meta,
                    in psa_egress_deparser_input_metadata_t out_meta)
                    {
        InternetChecksum() ck;
        apply {
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
            packet.emit(hdr.ethernet);
            packet.emit(hdr.vlan);
            packet.emit(hdr.ipv4);
            packet.emit(hdr.tcp);
            packet.emit(hdr.udp);
        }
}
IngressPipeline(MyIngressParser(),
                MyIngress(),
                MyIngressDeparser()) IPipeline;
EgressPipeline( MyEgressParser(),
                MyEgress(),
                MyEgressDeparser()) EPipeline;

PSA_Switch(IPipeline, PacketReplicationEngine(),EPipeline, BufferingQueueingEngine()) main;