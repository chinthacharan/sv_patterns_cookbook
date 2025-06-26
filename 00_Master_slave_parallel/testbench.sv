class tx_test;

  int port_num = 0;
  int dut_inst = 0;
  string type_str;

  task m_launch();
    $display("Starting mtxn: dut_inst=%0d, port_num=%0d, type=%s time=%t", dut_inst, port_num, type_str, $realtime);
    #5; //Intentional delay to model real world behavior
    $display("Completed mtxn: dut_inst=%0d, port_num=%0d, type=%s time=%t", dut_inst, port_num, type_str, $realtime);
  endtask

  task s_launch();
    $display("Starting stxn: dut_inst=%0d, port_num=%0d, type=%s time=%t", dut_inst, port_num, type_str, $realtime);
    #15; //Intentional delay to model real world behavior (assume slave takes more time to complete)
    $display("Completed stxn: dut_inst=%0d, port_num=%0d, type=%s time=%t", dut_inst, port_num, type_str, $realtime);
  endtask

endclass

class test;

  task body();
    $display("Starting Test...");

    for (int dut_inst = 0; dut_inst < 2; dut_inst++) begin
        for (int port_num = 0; port_num < 2; port_num++) begin
        fork
            automatic int a_dut_inst = dut_inst;
            automatic int a_port_num = port_num;
            begin
            tx_test slave_txn = new();
            slave_txn.dut_inst = a_dut_inst;
            slave_txn.port_num = a_port_num;
            slave_txn.type_str = "SLAVE";
            slave_txn.s_launch();
            end
        join_none
        end
    end

    fork
      begin 
        for (int dut_inst = 0; dut_inst < 2; dut_inst++) begin
          for (int port_num = 0; port_num < 2; port_num++) begin
            fork
              automatic int a_dut_inst = dut_inst;
              automatic int a_port_num = port_num;
              begin
                tx_test master_txn = new();
                master_txn.dut_inst = a_dut_inst;
                master_txn.port_num = a_port_num;
                master_txn.type_str = "MASTER";
                master_txn.m_launch();
              end
            join_none
          end
        end
        $display("Waiting for all master transactions to complete...");
        wait fork;
        $display("All master transactions are complete.");
      end
    join

    #5; // Let transactions run for a while
    $display("Calling $finish");
    $finish;
  endtask

endclass


module top();
  test t = new();
  initial t.body();
endmodule