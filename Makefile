.PHONY: all clean

FLAGS=-std=c++11 -O3 -Wall -Wextra -pedantic -Wfatal-errors -I.
FLAGS_INTEL=$(FLAGS) -DHAVE_SSE_INSTRUCTIONS
FLAGS_SSE4=$(FLAGS_INTEL) -msse4.2
FLAGS_AVX2=$(FLAGS_INTEL) -mavx2 -DHAVE_AVX2_INSTRUCTIONS
FLAGS_AVX512=$(FLAGS_INTEL) -mavx512f -DHAVE_AVX2_INSTRUCTIONS -DHAVE_AVX512F_INSTRUCTIONS
FLAGS_ARM=$(FLAGS) -mfpu=neon -DHAVE_NEON_INSTRUCTIONS

DEPS=utils/ansi.cpp utils/bits.cpp common.h fixed-memcmp.cpp
DEPS_SCALAR=swar64-strstr-v2.cpp swar32-strstr-v2.cpp
DEPS_SSE4=sse4-strstr.cpp sse4-strstr-unrolled.cpp sse4.2-strstr.cpp sse2-strstr.cpp utils/sse.cpp $(DEPS) $(DEPS_SCALAR)
DEPS_AVX2=avx2-strstr.cpp avx2-strstr-v2.cpp utils/avx2.cpp $(DEPS_SSE4)
DEPS_AVX512=avx512f-strstr.cpp avx512f-strstr-v2.cpp utils/avx512.cpp $(DEPS_AVX2)
DEPS_ARM=neon-strstr-v2.cpp $(DEPS_SCALAR)

ALL_INTEL=\
    validate \
    speedup \
    unittests \
    validate_avx2 \
    speedup_avx2 \
    unittests_avx2 \
    validate_avx512 \
    speedup_avx512 \
    unittests_avx512 \

ALL_ARM=\
    validate_arm \
    unittests_arm \
    speedup_arm

ALL=$(ALL_INTEL) $(ALL_ARM)

all: $(ALL_INTEL)

validate: src/validate.cpp src/application_base.cpp $(DEPS_SSE4)
	$(CXX) $(FLAGS_SSE4) src/validate.cpp -o $@

speedup: src/speedup.cpp src/application_base.cpp $(DEPS_SSE4)
	$(CXX) $(FLAGS_SSE4) -DNDEBUG src/speedup.cpp -o $@

unittests: src/unittests.cpp $(DEPS_SSE4)
	$(CXX) $(FLAGS_SSE4) src/unittests.cpp -o $@

validate_avx2: src/validate.cpp src/application_base.cpp $(DEPS_AVX2)
	$(CXX) $(FLAGS_AVX2) src/validate.cpp -o $@

speedup_avx2: src/speedup.cpp src/application_base.cpp $(DEPS_AVX2)
	$(CXX) $(FLAGS_AVX2) -DNDEBUG  src/speedup.cpp -o $@

unittests_avx2: src/unittests.cpp $(DEPS_AVX2)
	$(CXX) $(FLAGS_AVX2) src/unittests.cpp -o $@

validate_avx512: src/validate.cpp src/application_base.cpp $(DEPS_AVX512)
	$(CXX) $(FLAGS_AVX512) src/validate.cpp -o $@

speedup_avx512: src/speedup.cpp src/application_base.cpp $(DEPS_AVX512)
	$(CXX) $(FLAGS_AVX512) -DNDEBUG  src/speedup.cpp -o $@

unittests_avx512: src/unittests.cpp $(DEPS_AVX512)
	$(CXX) $(FLAGS_AVX512) src/unittests.cpp -o $@

validate_arm: src/validate.cpp src/application_base.cpp $(DEPS_ARM)
	$(CXX) $(FLAGS_ARM) src/validate.cpp -o $@

speedup_arm: src/speedup.cpp src/application_base.cpp $(DEPS_ARM)
	$(CXX) $(FLAGS_ARM) -DNDEBUG  src/speedup.cpp -o $@

unittests_arm: src/unittests.cpp $(DEPS_ARM)
	$(CXX) $(FLAGS_ARM) src/unittests.cpp -o $@

data/i386.txt:
	wget http://css.csail.mit.edu/6.858/2013/readings/i386.txt
	mv i386.txt data/i386.txt

data/words: data/i386.txt
	sh make_words.sh $^ $@

test: unittests validate data/words data/i386.txt
	./unittests
	./validate data/i386.txt data/words

run: speedup data/words data/i386.txt
	./speedup data/i386.txt data/words

test_avx2: unittests_avx2 validate_avx2 data/words data/i386.txt
	./unittests_avx2
	./validate_avx2 data/i386.txt data/words

run_avx2: speedup_avx2 data/words data/i386.txt
	./speedup_avx2 data/i386.txt data/words

test_avx512: unittests_avx512 validate_avx512 data/words data/i386.txt
	./unittests_avx512
	./validate_avx512 data/i386.txt data/words

run_avx512: speedup_avx512 data/words data/i386.txt
	./speedup_avx512 data/i386.txt data/words

test_arm: unittests_arm validate_arm data/words data/i386.txt
	./unittests_arm
	./validate_arm data/i386.txt data/words

run_arm: speedup_arm data/words data/i386.txt
	# my Raspberry Pi is slow, repeat count = 1 is enough
	./$< data/i386.txt data/words 1

clean:
	rm -f $(ALL)
