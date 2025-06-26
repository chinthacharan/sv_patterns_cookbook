# sv_patterns_cookbook

The goal is to:

- Simultaneously launch multiple master transactions for speed.
- Launch slave monitors/reactive sequences in parallel to catch activity immediately.
- Avoid simulation hang or premature exit by **correctly scoping `fork`, `join_none`, and `wait fork`**.

This pattern is useful when working with:

- Multiple DUTs connected back-to-back
- Bidirectional links (each DUT has master/slave ports)
- Scenarios requiring high-throughput and concurrency

---

## 🔧 Step-by-Step Execution

### ✅ Step 1: Launch Master Sequences in Parallel

```systemverilog
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
```

**Result:**
Simulation starts all master txns but ends immediately — because `join_none` doesn't wait.

---

### 🔁 Step 2: Add `wait fork` to Wait for Completion

```systemverilog
...
join_none
...
$display("Waiting for all master transactions to complete...");
wait fork;
$display("All master transactions are complete.");
```

**Result:**
Simulation now waits until all master transactions are complete.

---

### 🤝 Step 3: Launch Slave Sequences in Parallel

```systemverilog
// SLAVE
for (...) begin
  ...
    slave_txn.s_launch();
  ...
end

// MASTER
for (...) begin
  ...
    master_txn.m_launch();
  ...
end

wait fork;
```

**Issue:**
This waits for both MASTER and SLAVE — which is **not** the goal.

---

### ✔️ Step 4: Confine `wait fork` to MASTERs Only

```systemverilog
// Launch SLAVEs in background
for (...) begin
  ...
    slave_txn.s_launch();
  ...
end

// Confine wait fork to MASTERs
fork
  begin
    for (...) begin
      ...
        master_txn.m_launch();
      ...
    end
    $display("Waiting for all master transactions to complete...");
    wait fork;
    $display("All master transactions are complete.");
  end
join
```

**Result:**
Both master and slave sequences start at time 0, but only **masters** are waited on.

---

## 🧩 Key Takeaways

- ✅ Use `fork...join_none` to launch threads without blocking
- ✅ Use `wait fork` to **explicitly** wait for specific threads
- ✅ Nesting `fork-join` helps scope what gets waited on
- ❌ Don't rely on simulation to implicitly wait — it won’t

---

## 💬 License & Contribution

Feel free to fork, improve, and open a PR if you'd like to extend this pattern to UVM!
