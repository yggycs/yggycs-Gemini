#ifndef BITSET_H
#define BITSET_H

#include <bitset>
#include <cstdint>
#include <initializer_list>
#include <iostream>
#include <vector>

// 使用 var 遍历 set 对象，遍历方式有点像链表
#define FOR_BITSET(var, set) for(Bitset::bitlen_t var = set.first(); var != set.max_size(); var = set.next(var))

#define MAX_BITS_IN_BS 640

class Bitset: private std::bitset<MAX_BITS_IN_BS>{
public:
	typedef std::uint16_t bitlen_t;
private:
	typedef std::bitset<MAX_BITS_IN_BS> std_bs;
	// std::int64_t bits[4];
	// 移动拷贝构造函数，构造函数中调用了父类 std::bitset 的构造函数
	Bitset(std_bs&& base);
public:
    // 构造函数
	Bitset()=default;
	explicit Bitset(bitlen_t bit);
	Bitset(std::initializer_list<bitlen_t> bits);
	Bitset(std::vector<bitlen_t> list);
	// 1 的个数
	bitlen_t count() const;
	// Undefined behaviour if bitset is empty.
	// 首 1 的位置
	bitlen_t first() const;
	// Returns 0 if there is no next.
	// 下一个 1 的位置
	bitlen_t next(bitlen_t bit) const;
	// 找到第 n 个 1
	bitlen_t find_nth_1(bitlen_t bit)const;
	// 返回在 bit 位置上的值
	bool contains(bitlen_t bit) const;
	// 所有位置 1
	void set();
	// bit 位置上置 1
	void set(bitlen_t bit);
	// bit 位置上置 0
	void reset(bitlen_t bit);
	// bit 位置上翻转
	void flip(bitlen_t bit);
	// 所有位置 0
	void clear();
	// 返回 bitset 大小
	bitlen_t max_size() const;
	// 重载 |=
	Bitset& operator|=(const Bitset& other);
	// 重载 ==
	bool operator==(const Bitset& other) const;
	// 重载 []
	bool operator[](const bitlen_t bit)const;
	//Bitset& operator|=(bitlen_t other);
	// 友元函数，用于标准输出流
	friend std::ostream& operator<<(std::ostream& os, const Bitset& set);
	// 友元函数，用于重载 | 函数
	friend Bitset operator|(const Bitset& lhs, const Bitset& rhs);
};

#undef MAX_BITS_IN_BS

#endif // BITSET_H
