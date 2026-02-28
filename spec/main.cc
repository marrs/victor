#include "../src/includes.h"
#include "../src/buf.cc"
#include "../src/fennel-vm.cc"
#include "../src/groff.cc"
#include "font-mocks.h"
#include "fs-mocks.h"
#include "capture.h"
#include "test.h"

int main()
{
#include "util.cc"
#include "font.cc"
#include "groff.cc"
    return exit_testing();
}
