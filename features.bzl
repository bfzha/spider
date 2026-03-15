"""
Feature flag definitions for Spider project.
This file documents all feature flags, their default values, and their dependencies.
"""

# Feature flag definitions with metadata
FEATURE_FLAGS = {
    # Core features
    "sync": {
        "default": True,
        "description": "Enable synchronous crawling API",
        "rustc_flag": 'feature="sync"',
        "deps": ["tokio/sync"],
    },
    "serde": {
        "default": True,
        "description": "Enable serialization support",
        "rustc_flag": 'feature="serde"',
        "deps": ["serde", "serde_json", "serde_regex", "hashbrown/serde", "string-interner/serde", "smallvec/serde"],
    },
    "encoding": {
        "default": False,
        "description": "Enable character encoding detection",
        "rustc_flag": 'feature="encoding"',
        "deps": [],
    },
    "time": {
        "default": False,
        "description": "Enable time tracking",
        "rustc_flag": 'feature="time"',
        "deps": [],
    },
    "cookies": {
        "default": False,
        "description": "Enable cookie support",
        "rustc_flag": 'feature="cookies"',
        "deps": ["cookie", "reqwest/cookies"],
    },
    "headers": {
        "default": False,
        "description": "Enable header processing",
        "rustc_flag": 'feature="headers"',
        "deps": ["httpdate"],
    },
    "glob": {
        "default": False,
        "description": "Enable URL glob pattern support",
        "rustc_flag": 'feature="glob"',
        "deps": ["itertools"],
    },
    "full_resources": {
        "default": False,
        "description": "Download all page resources",
        "rustc_flag": 'feature="full_resources"',
        "deps": [],
    },
    "socks": {
        "default": False,
        "description": "Enable SOCKS proxy support",
        "rustc_flag": 'feature="socks"',
        "deps": ["reqwest/socks"],
    },

    # Browser automation features
    "chrome": {
        "default": False,
        "description": "Enable Chrome browser automation",
        "rustc_flag": 'feature="chrome"',
        "deps": ["chromey", "base64", "rand", "fastrand", "which", "home"],
        "implies": ["serde", "cookies"],
    },
    "chrome_headed": {
        "default": False,
        "description": "Run Chrome in headed mode",
        "rustc_flag": 'feature="chrome_headed"',
        "deps": [],
        "implies": ["chrome"],
    },
    "chrome_stealth": {
        "default": False,
        "description": "Enable Chrome stealth mode",
        "rustc_flag": 'feature="chrome_stealth"',
        "deps": [],
        "implies": ["chrome"],
    },
    "chrome_screenshot": {
        "default": False,
        "description": "Enable Chrome screenshot capability",
        "rustc_flag": 'feature="chrome_screenshot"',
        "deps": [],
        "implies": ["chrome"],
    },
    "chrome_intercept": {
        "default": False,
        "description": "Enable Chrome request interception",
        "rustc_flag": 'feature="chrome_intercept"',
        "deps": [],
        "implies": ["chrome"],
    },
    "smart": {
        "default": False,
        "description": "Enable smart crawling with Chrome interception",
        "rustc_flag": 'feature="smart"',
        "deps": [],
        "implies": ["chrome", "chrome_intercept"],
    },
    "webdriver": {
        "default": False,
        "description": "Enable WebDriver support",
        "rustc_flag": 'feature="webdriver"',
        "deps": ["thirtyfour", "rand", "fastrand"],
        "implies": ["serde"],
    },

    # LLM integration features
    "openai": {
        "default": False,
        "description": "Enable OpenAI integration",
        "rustc_flag": 'feature="openai"',
        "deps": ["async-openai", "tiktoken-rs", "serde_json"],
        "implies": ["chrome", "chrome_intercept", "serde"],
    },
    "gemini": {
        "default": False,
        "description": "Enable Gemini integration",
        "rustc_flag": 'feature="gemini"',
        "deps": ["gemini-rust", "serde_json"],
        "implies": ["chrome", "chrome_intercept", "serde"],
    },

    # Linux-specific features
    "io_uring": {
        "default": True,
        "description": "Enable io_uring for async I/O (Linux only)",
        "rustc_flag": 'feature="io_uring"',
        "deps": ["io-uring"],
        "platform": "linux",
    },

    # Cache features
    "cache": {
        "default": False,
        "description": "Enable HTTP request caching",
        "rustc_flag": 'feature="cache"',
        "deps": ["http-global-cache", "reqwest-middleware", "http-cache-reqwest", "http", "http-cache"],
        "implies": ["cache_request"],
    },
    "cache_mem": {
        "default": False,
        "description": "Enable in-memory HTTP caching",
        "rustc_flag": 'feature="cache_mem"',
        "deps": ["http-global-cache", "reqwest-middleware", "http-cache-reqwest", "http", "http-cache"],
        "implies": ["cache_request"],
    },
    "cache_openai": {
        "default": False,
        "description": "Enable OpenAI response caching",
        "rustc_flag": 'feature="cache_openai"',
        "deps": ["moka"],
    },

    # Scheduling features
    "cron": {
        "default": False,
        "description": "Enable cron-based scheduling",
        "rustc_flag": 'feature="cron"',
        "deps": ["async_job", "chrono", "cron", "async-trait"],
    },

    # Other features
    "sitemap": {
        "default": False,
        "description": "Enable sitemap parsing",
        "rustc_flag": 'feature="sitemap"',
        "deps": ["sitemap"],
    },
    "tracing": {
        "default": False,
        "description": "Enable tracing support",
        "rustc_flag": 'feature="tracing"',
        "deps": ["tracing"],
        "implies": ["tokio/tracing"],
    },
    "firewall": {
        "default": False,
        "description": "Enable firewall detection",
        "rustc_flag": 'feature="firewall"',
        "deps": ["spider_firewall"],
        "implies": ["chromey/firewall"],
    },
    "wreq": {
        "default": False,
        "description": "Use wreq HTTP client instead of reqwest",
        "rustc_flag": 'feature="wreq"',
        "deps": ["wreq", "wreq-util"],
    },
    "spider_cloud": {
        "default": False,
        "description": "Enable Spider Cloud integration",
        "rustc_flag": 'feature="spider_cloud"',
        "deps": [],
        "implies": ["serde"],
    },

    # Agent features
    "agent": {
        "default": False,
        "description": "Enable spider_agent integration",
        "rustc_flag": 'feature="agent"',
        "deps": ["spider_agent"],
    },
    "agent_openai": {
        "default": False,
        "description": "Enable agent with OpenAI",
        "rustc_flag": 'feature="agent_openai"',
        "deps": [],
        "implies": ["agent", "spider_agent/openai"],
    },
    "agent_chrome": {
        "default": False,
        "description": "Enable agent with Chrome",
        "rustc_flag": 'feature="agent_chrome"',
        "deps": ["dashmap"],
        "implies": ["agent", "chrome", "spider_agent/chrome"],
    },
    "agent_webdriver": {
        "default": False,
        "description": "Enable agent with WebDriver",
        "rustc_flag": 'feature="agent_webdriver"',
        "deps": [],
        "implies": ["agent", "spider_agent/webdriver"],
    },
    "agent_skills": {
        "default": False,
        "description": "Enable agent skills",
        "rustc_flag": 'feature="agent_skills"',
        "deps": [],
        "implies": ["agent", "spider_agent/skills"],
    },
    "agent_full": {
        "default": False,
        "description": "Enable full agent feature set",
        "rustc_flag": 'feature="agent_full"',
        "deps": [],
        "implies": ["agent", "agent_skills", "spider_agent/full"],
    },

    # Search providers
    "search": {
        "default": False,
        "description": "Enable search functionality",
        "rustc_flag": 'feature="search"',
        "deps": [],
        "implies": ["serde"],
    },
    "search_serper": {
        "default": False,
        "description": "Enable Serper search provider",
        "rustc_flag": 'feature="search_serper"',
        "deps": [],
        "implies": ["search"],
    },
    "search_brave": {
        "default": False,
        "description": "Enable Brave search provider",
        "rustc_flag": 'feature="search_brave"',
        "deps": [],
        "implies": ["search"],
    },
    "search_bing": {
        "default": False,
        "description": "Enable Bing search provider",
        "rustc_flag": 'feature="search_bing"',
        "deps": [],
        "implies": ["search"],
    },
    "search_tavily": {
        "default": False,
        "description": "Enable Tavily search provider",
        "rustc_flag": 'feature="search_tavily"',
        "deps": [],
        "implies": ["search"],
    },
}

# Build configuration presets
BUILD_PRESETS = {
    "basic": {
        "description": "Basic crawling with minimal features",
        "features": ["sync", "serde", "encoding", "time", "io_uring"],
    },
    "full": {
        "description": "All features enabled",
        "features": list(FEATURE_FLAGS.keys()),
    },
    "chrome": {
        "description": "Chrome-based crawling",
        "features": ["sync", "serde", "chrome", "encoding", "time"],
    },
    "agent": {
        "description": "Agent-based automation",
        "features": ["sync", "serde", "agent_openai", "agent_chrome", "encoding", "time"],
    },
}

def get_feature_deps(features):
    """Get all dependencies for a set of features."""
    deps = []
    for feature in features:
        if feature in FEATURE_FLAGS:
            deps.extend(FEATURE_FLAGS[feature].get("deps", []))
            # Include implied features
            for implied in FEATURE_FLAGS[feature].get("implies", []):
                if isinstance(implied, str) and implied in FEATURE_FLAGS:
                    deps.extend(FEATURE_FLAGS[implied].get("deps", []))
    return deps

def get_rustc_flags(features):
    """Get all rustc flags for a set of features."""
    flags = []
    for feature in features:
        if feature in FEATURE_FLAGS:
            flag = FEATURE_FLAGS[feature].get("rustc_flag")
            if flag:
                flags.extend(["--cfg", flag])
    return flags