use regex::Regex;
use std::collections::HashMap;
use xxhash_rust::xxh3::xxh3_64;

/// DanmakuMask: 滑动窗口 + 分桶 + 频控
#[flutter_rust_bridge::frb(opaque)]
pub struct DanmakuMask {
    base_window_ms: u32,     // 基础窗口（ms）
    bucket_count: u16,       // 桶数量
    max_frequency: u16,      // 最大允许频次

    use_normalization: bool,
    use_frequency_control: bool,

    // 运行时状态
    window_ms: u32,
    bucket_size_ms: u32,

    current_bucket: usize,  // Vec 索引
    last_shift_ms: u64,     // 上次滑动的时间戳（ms）

    // 桶内记录每个 hash 的出现次数（保证频控计数准确）
    buckets: Vec<HashMap<u64, u16>>,
    // 全局滑动窗口内每个 hash 的总次数
    freq_map: HashMap<u64, u16>,

    norm_re_space: Option<Regex>,
    norm_re_punct: Option<Regex>,
}

#[flutter_rust_bridge::frb(sync)]
impl DanmakuMask {
    pub fn new(
        base_window_ms: u32,
        bucket_count: u16,
        use_normalization: bool,
        use_frequency_control: bool,
        max_frequency: u16,
    ) -> Self {
        let bucket_count_usize = bucket_count.max(1) as usize;
        let bucket_size_ms = base_window_ms / bucket_count.max(1) as u32;

        let norm_re_space = use_normalization
            .then(|| Regex::new(r"\s+").unwrap());
        let norm_re_punct = use_normalization
            .then(|| Regex::new(r"[~!！?？,.，。]").unwrap());

        Self {
            base_window_ms,
            bucket_count,
            max_frequency,
            use_normalization,
            use_frequency_control,
            window_ms: base_window_ms,
            bucket_size_ms,
            current_bucket: 0,
            last_shift_ms: 0,
            // 用 HashMap 计数，避免去重时计数虚增
            buckets: (0..bucket_count_usize)
                .map(|_| HashMap::with_capacity(128))
                .collect(),
            freq_map: HashMap::with_capacity(1024),
            norm_re_space,
            norm_re_punct,
        }
    }

    /// 文本归一化
    fn normalize(&self, text: &str) -> String {
        if !self.use_normalization {
            return text.to_owned();
        }

        let mut s = text.trim().to_lowercase();
        if let Some(re) = &self.norm_re_space {
            s = re.replace_all(&s, "").to_string();
        }
        if let Some(re) = &self.norm_re_punct {
            s = re.replace_all(&s, "").to_string();
        }
        s
    }

    /// 滑动窗口，清理过期桶
    fn shift_if_needed(&mut self, now_ms: u64) {
        if self.last_shift_ms == 0 {
            self.last_shift_ms = now_ms;
            return;
        }

        while now_ms.saturating_sub(self.last_shift_ms) >= self.bucket_size_ms as u64 {
            self.last_shift_ms += self.bucket_size_ms as u64;
            self.current_bucket = (self.current_bucket + 1) % self.bucket_count as usize;

            // 清理即将被覆盖的桶（即将成为当前桶的那个旧桶）
            let expired = &mut self.buckets[self.current_bucket];
            for (&hash, &count) in expired.iter() {
                if let Some(v) = self.freq_map.get_mut(&hash) {
                    // 减去该桶内的出现次数，避免计数残留
                    if *v <= count {
                        self.freq_map.remove(&hash);
                    } else {
                        *v -= count;
                    }
                }
            }
            expired.clear();
        }
    }

    /// 重置状态
    pub fn reset(&mut self) {
        for bucket in &mut self.buckets {
            bucket.clear();
        }
        self.freq_map.clear();
        self.current_bucket = 0;
        self.last_shift_ms = 0;
        // window_ms 和 bucket_size_ms 无需改变，它们由构造函数固定
    }

    pub fn dispose(self) {
        // 消费所有权
    }
}

#[flutter_rust_bridge::frb]
impl DanmakuMask {
    /// 批量判断是否允许
    /// 返回 Vec<u8>：1 = 允许，0 = 屏蔽
    pub fn allow_list_batch(
        &mut self,
        texts: Vec<String>,
        now_ms: u64,
    ) -> Vec<u8> {
        self.shift_if_needed(now_ms);

        let mut results = Vec::with_capacity(texts.len());

        for text in texts {
            let normalized = self.normalize(&text);
            let hash = xxh3_64(normalized.as_bytes());

            // 确定当前实际允许的最大次数
            let effective_max: u16 = if self.use_frequency_control {
                self.max_frequency
            } else {
                1
            };

            let freq = *self.freq_map.get(&hash).unwrap_or(&0);
            let allowed = freq < effective_max;

            if allowed {
                let bucket = &mut self.buckets[self.current_bucket];
                *bucket.entry(hash).or_insert(0) += 1;
                *self.freq_map.entry(hash).or_insert(0) += 1;
            }

            results.push(if allowed { 1 } else { 0 });
        }

        results
    }
}