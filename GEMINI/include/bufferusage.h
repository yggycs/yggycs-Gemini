#ifndef BUFFERUSAGE_H
#define BUFFERUSAGE_H

#include <unordered_map>
#include "util.h"

class BufferUsage{
	struct pos_hash {
		// 对 () 操作符进行重载，重载后的 () 实际上为一 hash 函数， pos --hash--> size_t
		std::size_t operator()(const pos_t& pos) const {
			// pos_hash_t(强行将 pos 的内容解释为 pos_hash_t 类型) --hash--> size_t
			return std::hash<pos_t::pos_hash_t>{}(*reinterpret_cast<const pos_t::pos_hash_t*>(&pos));
		}
	};
	// 定义哈希映射 usage，每个 chip 用一个点来表示，usage 将点坐标哈希映射到一个 buffer 容量值
	std::unordered_map<pos_t, vol_t, pos_hash> usage;
	vol_t factor, max_vol;
	bool valid;
public:
	// 构造函数
	BufferUsage();
	BufferUsage(vol_t _max_vol);
	// 为芯片 chip 的 buffer 增加 size 的容量，其中 factor 为缩放因子
	// 当增加的容量大小不是 factor 的整数倍时，将 factor 置为 1 并更改每个 chip 的 buffer 容量值
	// 当芯片容量超过 max_vol 时，valid 变为无效
	bool add(pos_t chip, vol_t size);
	bool all_add(vol_t size);
	// 重载 bool，返回 valid 值
	operator bool() const;
	// 重载操作符，两个 BufferUsage 相加，缩放因子 factor 变为 1
	BufferUsage& operator+=(const BufferUsage& other);
	BufferUsage operator+(const BufferUsage& other) const;
	// 比较两个 BufferUsage，对每个 pos 取最大容量
	void max(const BufferUsage& other);
	// 取当前 BufferUsage 中每个 pos 的最大容量
	vol_t max() const;
	// 计算当前 BufferUsage 的平均容量
	double avg() const;
	// BufferUsage 中的每个 pos 容量乘以 n
	bool multiple(vol_t n);
	vol_t get_max_vol() const;
	// 输出最大容量和平均容量
	friend std::ostream& operator<<(std::ostream& os, const BufferUsage& usage);
};

#endif // BUFFERUSAGE_H
