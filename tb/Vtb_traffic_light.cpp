#include <gtest/gtest.h>
#include <memory>
#include "verilated.h"
#include "verilated_vcd_c.h"

#include "Vtraffic_light_top.h"
#include "Vtraffic_light_top___024root.h"

constexpr uint8_t ST_GREEN = 0b00;
constexpr uint8_t ST_YELLOW = 0b01;
constexpr uint8_t ST_PED = 0b11;

constexpr int DIV_LIMIT_1S = 20;

//фикстура
class TrafficLightTest : public ::testing::Test {
protected:
    std::unique_ptr<VerilatedContext> contextp;
    std::unique_ptr<Vtraffic_light_top> tested_u;
    std::unique_ptr<VerilatedVcdC> tfp;

    void SetUp() override {
        contextp = std::make_unique<VerilatedContext>();
        contextp->traceEverOn(true);
        tested_u = std::make_unique<Vtraffic_light_top>(contextp.get());

        tfp = std::make_unique<VerilatedVcdC>();
        tested_u->trace(tfp.get(), 99);
        tfp->open("wave.vcd");

        tested_u->CLOCK_50 = 0;
        tested_u->KEY = 0b10;
        tested_u->eval();
    }

    void TearDown() override {
        if (tfp) {
            tfp->close();
        }
        tested_u->final();
    }

    //@(posedge CLOCK_50)
    void tick(int cycles = 1) {
        for (int i = 0; i < cycles; ++i) {
            tested_u->CLOCK_50 = 0;
            tested_u->eval();
            contextp->timeInc(10);
            tfp->dump(contextp->time());

            tested_u->CLOCK_50 = 1;
            tested_u->eval();
            contextp->timeInc(10);
            tfp->dump(contextp->time());
        }
    }

    void press_ped() {
        tested_u->KEY &= ~(1 << 1); // KEY[1] = 0 (нажали)
        tick(1);
        tested_u->KEY |= (1 << 1);  // KEY[1] = 1 (отпустили)
        tick(1);
    }

    //геттеры для чтения внутренних сигналов tested_u
    uint8_t get_state() {
        return tested_u->rootp->traffic_light_top__DOT__fsm_inst__DOT__fsm_state;
    }
    uint8_t get_time_left() {
        return tested_u->rootp->traffic_light_top__DOT__time_left;
    }

    void check_outputs() {
        uint8_t state = get_state();
        switch (state) {
        case ST_GREEN:
            EXPECT_EQ(tested_u->LEDR, 0b001) << "GREEN: LEDR is not 3'b001";
            EXPECT_EQ(tested_u->LEDG, 0b10) << "GREEN: LEDG is not 2'b10";
            break;
        case ST_YELLOW:
            EXPECT_EQ(tested_u->LEDR & 0b101, 0) << "YELLOW: Not only LEDR[1] is blinking";
            EXPECT_EQ(tested_u->LEDG, 0b10) << "YELLOW: LEDG is not 2'b10";
            break;
        case ST_PED:
            EXPECT_EQ(tested_u->LEDR, 0b100) << "PED: LEDR is not 3'b100";
            EXPECT_EQ(tested_u->LEDG, 0b01) << "PED: LEDG is not 2'b01";
            break;
        default:
            FAIL() << "Invalid fsm_state == 2'b10";
        }
    }

    template <typename Predicate>
    void wait_until(Predicate cond, int max_cycles = 5000, const std::string& msg = "") {
        int count = 0;
        while (!cond()) {
            tick(1);
            if (++count > max_cycles) {
                FAIL() << "Wait timeout (" << max_cycles << " cycles): " << msg;
            }
        }
    }
};

TEST_F(TrafficLightTest, FullCycleAndPedestrianButton) {
    tested_u->KEY = 0b10;
    tick(5);
    tested_u->KEY |= (1 << 0);
    tick(2);

    ASSERT_EQ(get_state(), ST_GREEN) << "FSM is not in GREEN state after reset";
    ASSERT_EQ(get_time_left(), 15) << "time_left is not 15 after reset";
    check_outputs();

    wait_until([&]() { return get_state() == ST_GREEN && get_time_left() == 12; },
        1000, "Waiting for time_left == 12 in GREEN state")");

    press_ped();
    tick(2);

    ASSERT_EQ(get_state(), ST_YELLOW) << "Pedestrian button did not transition FSM to YELLOW";
    ASSERT_EQ(get_time_left(), 3) << "Timer did not shorten to 3s";
    check_outputs();

    uint8_t b0 = (tested_u->LEDR >> 1) & 1;
    tick(DIV_LIMIT_1S / 4);
    uint8_t b1 = (tested_u->LEDR >> 1) & 1;
    EXPECT_NE(b0, b1) << "LEDR is not blinking during YELLOW phase";

    wait_until([&]() { return get_state() == ST_PED; }, 1000, "Transition to PED state");
    tick(1);
    EXPECT_EQ(get_time_left(), 10) << "PED: time_left did not start at 10";
    check_outputs();

    wait_until([&]() { return get_state() == ST_GREEN; }, 1000, "Return to GREEN state");
    tick(1);
    check_outputs();
    EXPECT_EQ(get_time_left(), 15) << "GREEN: timer did not restart at 15";

    wait_until([&]() { return get_state() == ST_GREEN && get_time_left() == 3; },
        2000, "Waiting for time_left == 3 in GREEN state");
    tick(3);
    ASSERT_EQ(get_state(), ST_YELLOW) << "No natural transition to YELLOW at time_left == 3";

    // 7. Complete remaining cycle PED -> GREEN
    wait_until([&]() { return get_state() == ST_PED; }, 1000, "Natural transition to PED state");
    wait_until([&]() { return get_state() == ST_GREEN; }, 1000, "Final return to GREEN state");
}
