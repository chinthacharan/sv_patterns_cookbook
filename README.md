# sv_patterns_cookbook

I put together a simple example that shows how master-slave sequences could work in parallel. Nothing groundbreaking, but thought it might be useful for others.

Scenario: Lets say we have to launch 5000 txns from master and its highly inefficient to launch these transactions serially. So first we will launch all these master transactions parallely then have the slave sequence launching in parallel to this master that way we can capture the information as soon as the master launches it. To make it interesting assume we have two DUT's connected back to back communicating with each other so we need to launch master and slave on both the DUT's and each DUT has two ports namely master and slave(You can find the standalone in the end).


Step 1: Launch all master sequences in parallel


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


Result: 

Starting Test...

Starting mtxn: dut_inst=0, port_num=0, type=MASTER time=                   0

Starting mtxn: dut_inst=0, port_num=1, type=MASTER time=                   0

Starting mtxn: dut_inst=1, port_num=0, type=MASTER time=                   0

Starting mtxn: dut_inst=1, port_num=1, type=MASTER time=                   0

Calling $finish


Analysis: We successfully launched all the master sequences parallely at time = 0. But see how the simulation ends without waiting for master transactions to complete. Since we used fork-join_none to launch them parallel this also caused the simulation to end without waiting for it to complete.


Step 2: Need a wait fork to wait for this fork to complete

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


Result: 

Starting Test...

Waiting for all master transactions to complete...

Starting mtxn: dut_inst=0, port_num=0, type=MASTER time=                   0

Starting mtxn: dut_inst=0, port_num=1, type=MASTER time=                   0

Starting mtxn: dut_inst=1, port_num=0, type=MASTER time=                   0

Starting mtxn: dut_inst=1, port_num=1, type=MASTER time=                   0

Completed mtxn: dut_inst=0, port_num=0, type=MASTER time=                   5

Completed mtxn: dut_inst=0, port_num=1, type=MASTER time=                   5

Completed mtxn: dut_inst=1, port_num=0, type=MASTER time=                   5

Completed mtxn: dut_inst=1, port_num=1, type=MASTER time=                   5

All master transactions are complete.

Calling $finish


Analysis: We see that all master transactions are launched parallel and simulation is waiting for it to complete.


Step 3: Now launch slave sequence in parallel but we dont need to wait for slave sequence to complete 


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


Result: 

Starting Test...

Waiting for all master transactions to complete...

Starting stxn: dut_inst=0, port_num=0, type=SLAVE time=                   0

Starting stxn: dut_inst=0, port_num=1, type=SLAVE time=                   0

Starting stxn: dut_inst=1, port_num=0, type=SLAVE time=                   0

Starting stxn: dut_inst=1, port_num=1, type=SLAVE time=                   0

Starting mtxn: dut_inst=0, port_num=0, type=MASTER time=                   0

Starting mtxn: dut_inst=0, port_num=1, type=MASTER time=                   0

Starting mtxn: dut_inst=1, port_num=0, type=MASTER time=                   0

Starting mtxn: dut_inst=1, port_num=1, type=MASTER time=                   0

Completed mtxn: dut_inst=0, port_num=0, type=MASTER time=                   5

Completed mtxn: dut_inst=0, port_num=1, type=MASTER time=                   5

Completed mtxn: dut_inst=1, port_num=0, type=MASTER time=                   5

Completed mtxn: dut_inst=1, port_num=1, type=MASTER time=                   5

Completed stxn: dut_inst=0, port_num=0, type=SLAVE time=                  15

Completed stxn: dut_inst=0, port_num=1, type=SLAVE time=                  15

Completed stxn: dut_inst=1, port_num=0, type=SLAVE time=                  15

Completed stxn: dut_inst=1, port_num=1, type=SLAVE time=                  15

All master transactions are complete.

Calling $finish


Analysis: But we dont want to wait for slave txn to complete so we should confine the wait fork only for master not for slave at the moment it is waiting for both.


Step 4: Confine the wait fork


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

      begin // thread to capture wait_fork for all forked off transaction threads

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


Result: 

Starting Test...

Starting stxn: dut_inst=0, port_num=0, type=SLAVE time=                   0

Starting stxn: dut_inst=0, port_num=1, type=SLAVE time=                   0

Starting stxn: dut_inst=1, port_num=0, type=SLAVE time=                   0

Starting stxn: dut_inst=1, port_num=1, type=SLAVE time=                   0

Waiting for all master transactions to complete...

Starting mtxn: dut_inst=0, port_num=0, type=MASTER time=                   0

Starting mtxn: dut_inst=0, port_num=1, type=MASTER time=                   0

Starting mtxn: dut_inst=1, port_num=0, type=MASTER time=                   0

Starting mtxn: dut_inst=1, port_num=1, type=MASTER time=                   0

Completed mtxn: dut_inst=0, port_num=0, type=MASTER time=                   5

Completed mtxn: dut_inst=0, port_num=1, type=MASTER time=                   5

Completed mtxn: dut_inst=1, port_num=0, type=MASTER time=                   5

Completed mtxn: dut_inst=1, port_num=1, type=MASTER time=                   5

All master transactions are complete.

Calling $finish


Analysis: This is our expectation that both master and slave is launched at 0 and we only wait for master transactions to complete and slave can parallely run but we should not wait for slave.


Final code: 


class tx_test;

  int port_num = 0;

  int dut_inst = 0;

  string type_str;


  task m_launch();

    $display("Starting mtxn: dut_inst=%0d, port_num=%0d, type=%s time=%t", dut_inst, port_num, type_str, $realtime);

    #5;

    $display("Completed mtxn: dut_inst=%0d, port_num=%0d, type=%s time=%t", dut_inst, port_num, type_str, $realtime);

  endtask

  task s_launch();

    $display("Starting stxn: dut_inst=%0d, port_num=%0d, type=%s time=%t", dut_inst, port_num, type_str, $realtime);

    #15;

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
