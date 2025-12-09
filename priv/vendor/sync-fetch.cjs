var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};

// node_modules/sync-fetch/src/headers.js
var require_headers = __commonJS({
  "node_modules/sync-fetch/src/headers.js"(exports2, module2) {
    var http = require("node:http");
    var _state = /* @__PURE__ */ Symbol("headers map");
    function prepareHeaderName(name) {
      name = name.toLowerCase();
      http.validateHeaderName(name);
      return name;
    }
    function prepareHeader(name, value) {
      name = prepareHeaderName(name);
      value = (value + "").trim();
      http.validateHeaderValue(name, value);
      return [name, value];
    }
    var SyncHeaders2 = class _SyncHeaders {
      constructor(headers) {
        this[_state] = {};
        if (headers instanceof _SyncHeaders) {
          this[_state] = headers.raw();
        } else if (headers != null && headers[Symbol.iterator] != null) {
          if (typeof headers[Symbol.iterator] !== "function") {
            throw new TypeError("Header pairs must be iterable");
          }
          for (const header of headers) {
            if (header == null || typeof header[Symbol.iterator] !== "function") {
              throw new TypeError("Header pairs must be iterable");
            }
            if (typeof header === "string") {
              throw new TypeError("Each header pair must be an iterable object");
            }
            const pair = Array.from(header);
            if (pair.length !== 2) {
              throw new TypeError("Each header pair must be a name/value tuple");
            }
            const [name, value] = pair;
            this.append(name, value);
          }
        } else if (typeof headers === "object") {
          for (const name of Object.keys(headers)) {
            this.set(name, headers[name]);
          }
        } else if (headers !== void 0) {
          throw new TypeError("The provided value is not of type '(sequence<sequence<ByteString>> or record<ByteString, ByteString>)'");
        }
      }
      append(name, value) {
        [name, value] = prepareHeader(name, value);
        if (this[_state][name]) {
          this[_state][name].push(value);
        } else {
          this[_state][name] = [value];
        }
      }
      delete(name) {
        name = prepareHeaderName(name);
        delete this[_state][name];
      }
      entries() {
        return this.keys().map((key) => [key, this.get(key)]);
      }
      forEach(callback, thisArg) {
        for (const [name, value] of this.entries()) {
          callback.call(thisArg ?? null, value, name, this);
        }
      }
      get(name) {
        name = prepareHeaderName(name);
        if (this.has(name)) {
          return this[_state][name].join(", ");
        }
        return null;
      }
      getSetCookie() {
        const name = "set-cookie";
        if (this.has(name)) {
          return this[_state][name].slice();
        }
        return [];
      }
      has(name) {
        name = prepareHeaderName(name);
        return Object.prototype.hasOwnProperty.call(this[_state], name);
      }
      keys() {
        return Object.keys(this[_state]).sort();
      }
      set(name, value) {
        [name, value] = prepareHeader(name, value);
        this[_state][name] = [value];
      }
      raw() {
        const headers = {};
        for (const name of this.keys()) {
          headers[name] = this[_state][name].slice();
        }
        return headers;
      }
      values() {
        return this.keys().map((key) => this.get(key));
      }
      *[Symbol.iterator]() {
        for (const entry of this.entries()) {
          yield entry;
        }
      }
      get [Symbol.toStringTag]() {
        return "Headers";
      }
    };
    Object.defineProperties(SyncHeaders2.prototype, {
      append: { enumerable: true },
      delete: { enumerable: true },
      entries: { enumerable: true },
      forEach: { enumerable: true },
      get: { enumerable: true },
      getSetCookie: { enumerable: true },
      has: { enumerable: true },
      keys: { enumerable: true },
      set: { enumerable: true },
      values: { enumerable: true }
    });
    function initializeHeaders(rawHeaders) {
      const headers = new SyncHeaders2();
      headers[_state] = rawHeaders;
      return headers;
    }
    module2.exports = { SyncHeaders: SyncHeaders2, initializeHeaders };
  }
});

// node_modules/sync-fetch/src/error.js
var require_error = __commonJS({
  "node_modules/sync-fetch/src/error.js"(exports2, module2) {
    var FetchError2 = class extends Error {
      constructor(message, type, systemError) {
        super(message);
        this.type = type;
        if (systemError) {
          this.code = this.errno = systemError.code;
        }
      }
      get name() {
        return "FetchError";
      }
      get [Symbol.toStringTag]() {
        return "FetchError";
      }
    };
    var errors = {
      TypeError
    };
    function deserializeError2(name, init) {
      if (name in errors) {
        return new errors[name](...init);
      } else {
        return new FetchError2(...init);
      }
    }
    module2.exports = { FetchError: FetchError2, deserializeError: deserializeError2 };
  }
});

// node_modules/whatwg-mimetype/lib/utils.js
var require_utils = __commonJS({
  "node_modules/whatwg-mimetype/lib/utils.js"(exports2) {
    "use strict";
    exports2.removeLeadingAndTrailingHTTPWhitespace = (string) => {
      return string.replace(/^[ \t\n\r]+/u, "").replace(/[ \t\n\r]+$/u, "");
    };
    exports2.removeTrailingHTTPWhitespace = (string) => {
      return string.replace(/[ \t\n\r]+$/u, "");
    };
    exports2.isHTTPWhitespaceChar = (char) => {
      return char === " " || char === "	" || char === "\n" || char === "\r";
    };
    exports2.solelyContainsHTTPTokenCodePoints = (string) => {
      return /^[-!#$%&'*+.^_`|~A-Za-z0-9]*$/u.test(string);
    };
    exports2.soleyContainsHTTPQuotedStringTokenCodePoints = (string) => {
      return /^[\t\u0020-\u007E\u0080-\u00FF]*$/u.test(string);
    };
    exports2.asciiLowercase = (string) => {
      return string.replace(/[A-Z]/ug, (l) => l.toLowerCase());
    };
    exports2.collectAnHTTPQuotedString = (input, position) => {
      let value = "";
      position++;
      while (true) {
        while (position < input.length && input[position] !== '"' && input[position] !== "\\") {
          value += input[position];
          ++position;
        }
        if (position >= input.length) {
          break;
        }
        const quoteOrBackslash = input[position];
        ++position;
        if (quoteOrBackslash === "\\") {
          if (position >= input.length) {
            value += "\\";
            break;
          }
          value += input[position];
          ++position;
        } else {
          break;
        }
      }
      return [value, position];
    };
  }
});

// node_modules/whatwg-mimetype/lib/mime-type-parameters.js
var require_mime_type_parameters = __commonJS({
  "node_modules/whatwg-mimetype/lib/mime-type-parameters.js"(exports2, module2) {
    "use strict";
    var {
      asciiLowercase,
      solelyContainsHTTPTokenCodePoints,
      soleyContainsHTTPQuotedStringTokenCodePoints
    } = require_utils();
    module2.exports = class MIMETypeParameters {
      constructor(map) {
        this._map = map;
      }
      get size() {
        return this._map.size;
      }
      get(name) {
        name = asciiLowercase(String(name));
        return this._map.get(name);
      }
      has(name) {
        name = asciiLowercase(String(name));
        return this._map.has(name);
      }
      set(name, value) {
        name = asciiLowercase(String(name));
        value = String(value);
        if (!solelyContainsHTTPTokenCodePoints(name)) {
          throw new Error(`Invalid MIME type parameter name "${name}": only HTTP token code points are valid.`);
        }
        if (!soleyContainsHTTPQuotedStringTokenCodePoints(value)) {
          throw new Error(`Invalid MIME type parameter value "${value}": only HTTP quoted-string token code points are valid.`);
        }
        return this._map.set(name, value);
      }
      clear() {
        this._map.clear();
      }
      delete(name) {
        name = asciiLowercase(String(name));
        return this._map.delete(name);
      }
      forEach(callbackFn, thisArg) {
        this._map.forEach(callbackFn, thisArg);
      }
      keys() {
        return this._map.keys();
      }
      values() {
        return this._map.values();
      }
      entries() {
        return this._map.entries();
      }
      [Symbol.iterator]() {
        return this._map[Symbol.iterator]();
      }
    };
  }
});

// node_modules/whatwg-mimetype/lib/parser.js
var require_parser = __commonJS({
  "node_modules/whatwg-mimetype/lib/parser.js"(exports2, module2) {
    "use strict";
    var {
      removeLeadingAndTrailingHTTPWhitespace,
      removeTrailingHTTPWhitespace,
      isHTTPWhitespaceChar,
      solelyContainsHTTPTokenCodePoints,
      soleyContainsHTTPQuotedStringTokenCodePoints,
      asciiLowercase,
      collectAnHTTPQuotedString
    } = require_utils();
    module2.exports = (input) => {
      input = removeLeadingAndTrailingHTTPWhitespace(input);
      let position = 0;
      let type = "";
      while (position < input.length && input[position] !== "/") {
        type += input[position];
        ++position;
      }
      if (type.length === 0 || !solelyContainsHTTPTokenCodePoints(type)) {
        return null;
      }
      if (position >= input.length) {
        return null;
      }
      ++position;
      let subtype = "";
      while (position < input.length && input[position] !== ";") {
        subtype += input[position];
        ++position;
      }
      subtype = removeTrailingHTTPWhitespace(subtype);
      if (subtype.length === 0 || !solelyContainsHTTPTokenCodePoints(subtype)) {
        return null;
      }
      const mimeType = {
        type: asciiLowercase(type),
        subtype: asciiLowercase(subtype),
        parameters: /* @__PURE__ */ new Map()
      };
      while (position < input.length) {
        ++position;
        while (isHTTPWhitespaceChar(input[position])) {
          ++position;
        }
        let parameterName = "";
        while (position < input.length && input[position] !== ";" && input[position] !== "=") {
          parameterName += input[position];
          ++position;
        }
        parameterName = asciiLowercase(parameterName);
        if (position < input.length) {
          if (input[position] === ";") {
            continue;
          }
          ++position;
        }
        let parameterValue = null;
        if (input[position] === '"') {
          [parameterValue, position] = collectAnHTTPQuotedString(input, position);
          while (position < input.length && input[position] !== ";") {
            ++position;
          }
        } else {
          parameterValue = "";
          while (position < input.length && input[position] !== ";") {
            parameterValue += input[position];
            ++position;
          }
          parameterValue = removeTrailingHTTPWhitespace(parameterValue);
          if (parameterValue === "") {
            continue;
          }
        }
        if (parameterName.length > 0 && solelyContainsHTTPTokenCodePoints(parameterName) && soleyContainsHTTPQuotedStringTokenCodePoints(parameterValue) && !mimeType.parameters.has(parameterName)) {
          mimeType.parameters.set(parameterName, parameterValue);
        }
      }
      return mimeType;
    };
  }
});

// node_modules/whatwg-mimetype/lib/serializer.js
var require_serializer = __commonJS({
  "node_modules/whatwg-mimetype/lib/serializer.js"(exports2, module2) {
    "use strict";
    var { solelyContainsHTTPTokenCodePoints } = require_utils();
    module2.exports = (mimeType) => {
      let serialization = `${mimeType.type}/${mimeType.subtype}`;
      if (mimeType.parameters.size === 0) {
        return serialization;
      }
      for (let [name, value] of mimeType.parameters) {
        serialization += ";";
        serialization += name;
        serialization += "=";
        if (!solelyContainsHTTPTokenCodePoints(value) || value.length === 0) {
          value = value.replace(/(["\\])/ug, "\\$1");
          value = `"${value}"`;
        }
        serialization += value;
      }
      return serialization;
    };
  }
});

// node_modules/whatwg-mimetype/lib/mime-type.js
var require_mime_type = __commonJS({
  "node_modules/whatwg-mimetype/lib/mime-type.js"(exports2, module2) {
    "use strict";
    var MIMETypeParameters = require_mime_type_parameters();
    var parse = require_parser();
    var serialize = require_serializer();
    var {
      asciiLowercase,
      solelyContainsHTTPTokenCodePoints
    } = require_utils();
    module2.exports = class MIMEType {
      constructor(string) {
        string = String(string);
        const result = parse(string);
        if (result === null) {
          throw new Error(`Could not parse MIME type string "${string}"`);
        }
        this._type = result.type;
        this._subtype = result.subtype;
        this._parameters = new MIMETypeParameters(result.parameters);
      }
      static parse(string) {
        try {
          return new this(string);
        } catch (e) {
          return null;
        }
      }
      get essence() {
        return `${this.type}/${this.subtype}`;
      }
      get type() {
        return this._type;
      }
      set type(value) {
        value = asciiLowercase(String(value));
        if (value.length === 0) {
          throw new Error("Invalid type: must be a non-empty string");
        }
        if (!solelyContainsHTTPTokenCodePoints(value)) {
          throw new Error(`Invalid type ${value}: must contain only HTTP token code points`);
        }
        this._type = value;
      }
      get subtype() {
        return this._subtype;
      }
      set subtype(value) {
        value = asciiLowercase(String(value));
        if (value.length === 0) {
          throw new Error("Invalid subtype: must be a non-empty string");
        }
        if (!solelyContainsHTTPTokenCodePoints(value)) {
          throw new Error(`Invalid subtype ${value}: must contain only HTTP token code points`);
        }
        this._subtype = value;
      }
      get parameters() {
        return this._parameters;
      }
      toString() {
        return serialize(this);
      }
      isJavaScript({ prohibitParameters = false } = {}) {
        switch (this._type) {
          case "text": {
            switch (this._subtype) {
              case "ecmascript":
              case "javascript":
              case "javascript1.0":
              case "javascript1.1":
              case "javascript1.2":
              case "javascript1.3":
              case "javascript1.4":
              case "javascript1.5":
              case "jscript":
              case "livescript":
              case "x-ecmascript":
              case "x-javascript": {
                return !prohibitParameters || this._parameters.size === 0;
              }
              default: {
                return false;
              }
            }
          }
          case "application": {
            switch (this._subtype) {
              case "ecmascript":
              case "javascript":
              case "x-ecmascript":
              case "x-javascript": {
                return !prohibitParameters || this._parameters.size === 0;
              }
              default: {
                return false;
              }
            }
          }
          default: {
            return false;
          }
        }
      }
      isXML() {
        return this._subtype === "xml" && (this._type === "text" || this._type === "application") || this._subtype.endsWith("+xml");
      }
      isHTML() {
        return this._subtype === "html" && this._type === "text";
      }
    };
  }
});

// node_modules/sync-fetch/src/body.js
var require_body = __commonJS({
  "node_modules/sync-fetch/src/body.js"(exports2, module2) {
    var Stream = require("stream");
    var MIMEType = require_mime_type();
    var { FetchError: FetchError2 } = require_error();
    var _state = /* @__PURE__ */ Symbol("SyncFetch Internals");
    function getMimeType(body) {
      if (!body.headers.has("content-type")) {
        return null;
      }
      let essence = null;
      let charset = null;
      let mimeType = null;
      for (const type of body.headers.raw()["content-type"]) {
        mimeType = new MIMEType(type);
        if (mimeType.essence !== essence) {
          charset = mimeType.parameters.get("charset") ?? null;
          essence = mimeType.essence;
        } else if (!mimeType.parameters.has("charset") && charset !== null) {
          mimeType.parameters.set("charset", charset);
        }
      }
      return mimeType.toString();
    }
    var Body = class _Body {
      static mixin(proto) {
        for (const name of Object.getOwnPropertyNames(_Body.prototype)) {
          if (name === "constructor") {
            continue;
          }
          const desc = Object.getOwnPropertyDescriptor(_Body.prototype, name);
          Object.defineProperty(proto, name, {
            ...desc,
            enumerable: true
          });
        }
      }
      arrayBuffer() {
        checkBody(this);
        const buf = consumeBody(this);
        return buf.buffer.slice(buf.byteOffset, buf.byteOffset + buf.byteLength);
      }
      text() {
        checkBody(this);
        return consumeBody(this).toString();
      }
      json() {
        checkBody(this);
        try {
          return JSON.parse(consumeBody(this).toString());
        } catch (err) {
          throw new FetchError2(`invalid json response body at ${this.url} reason: ${err.message}`, "invalid-json");
        }
      }
      buffer() {
        checkBody(this);
        return Buffer.from(consumeBody(this));
      }
      textConverted() {
        throw new FetchError2("textConverted not implemented");
      }
      blob() {
        checkBody(this);
        return new Blob([this.arrayBuffer()], {
          type: getMimeType(this) ?? ""
        });
      }
      get body() {
        return this[_state].bodyStream;
      }
      get bodyUsed() {
        if (this[_state].bodyStream && this[_state].bodyStream.state === "closed") {
          this[_state].bodyUsed = true;
        }
        return this[_state].bodyUsed;
      }
    };
    function checkBody(body) {
      if (body[_state].bodyError) {
        throw body[_state].bodyError;
      }
      if (body.bodyUsed) {
        throw new TypeError(`body used already for: ${body.url}`);
      }
    }
    function consumeBody(body) {
      body[_state].bodyUsed = true;
      return body[_state].body || Buffer.alloc(0);
    }
    function parseBodyType(body) {
      if (body == null) {
        return "Null";
      } else if (body.constructor.name === "URLSearchParams") {
        return "URLSearchParams";
      } else if (Buffer.isBuffer(body)) {
        return "Buffer";
      } else if (Object.prototype.toString.call(body) === "[object ArrayBuffer]") {
        return "ArrayBuffer";
      } else if (ArrayBuffer.isView(body)) {
        return "ArrayBufferView";
      } else if (body instanceof Stream) {
        return "Stream";
      } else {
        return "String";
      }
    }
    function parseBody(body, type = parseBodyType(body)) {
      switch (type) {
        case "Null":
          return null;
        case "URLSearchParams":
          return Buffer.from(body.toString());
        case "Buffer":
          return body;
        case "ArrayBuffer":
          return Buffer.from(body);
        case "ArrayBufferView":
          return Buffer.from(body.buffer, body.byteOffset, body.byteLength);
        case "String":
          return Buffer.from(String(body));
        default:
          throw new TypeError(`sync-fetch does not support bodies of type: ${type}`);
      }
    }
    function createStream(buffer) {
      return new ReadableStream({
        start(controller) {
          controller.enqueue(buffer);
          controller.close();
        }
      });
    }
    module2.exports = { Body, checkBody, parseBody, createStream, _state };
  }
});

// node_modules/sync-fetch/src/request.js
var require_request = __commonJS({
  "node_modules/sync-fetch/src/request.js"(exports2, module2) {
    var util = require("util");
    var { Body, checkBody, parseBody, createStream, _state } = require_body();
    var { SyncHeaders: SyncHeaders2 } = require_headers();
    var SyncRequest2 = class _SyncRequest {
      constructor(resource, init = {}) {
        const nodeFetchOptions = Object.assign(resource instanceof _SyncRequest ? { ...resource[_state] } : {}, init);
        const buffer = nodeFetchOptions.body ? parseBody(nodeFetchOptions.body) : null;
        if (resource instanceof _SyncRequest) {
          const request2 = serializeRequest2(resource);
          resource = request2[0];
          init = Object.assign(request2[1], init);
        }
        const request = new Request(resource, init);
        Object.defineProperty(this, _state, {
          value: {
            body: buffer,
            bodyStream: buffer ? createStream(buffer) : null,
            bodyUsed: false,
            cache: request.cache,
            credentials: request.credentials,
            destination: request.destination,
            headers: new SyncHeaders2(request.headers),
            integrity: request.integrity,
            keepalive: request.keepalive,
            method: request.method,
            mode: request.mode,
            redirect: request.redirect,
            referrer: request.referrer,
            referrerPolicy: request.referrerPolicy,
            signal: request.signal,
            url: request.url,
            // node-fetch
            follow: nodeFetchOptions.follow,
            timeout: nodeFetchOptions.timeout,
            compress: nodeFetchOptions.compress,
            size: nodeFetchOptions.size,
            agent: nodeFetchOptions.agent
          },
          enumerable: false
        });
      }
      get [Symbol.toStringTag]() {
        return "Request";
      }
      get cache() {
        return this[_state].cache;
      }
      get counter() {
        return 0;
      }
      get credentials() {
        return this[_state].credentials;
      }
      get destination() {
        return this[_state].destination;
      }
      get headers() {
        return this[_state].headers;
      }
      get integrity() {
        return this[_state].integrity;
      }
      get method() {
        return this[_state].method;
      }
      get mode() {
        return this[_state].mode;
      }
      get priority() {
        return this[_state].priority;
      }
      get redirect() {
        return this[_state].redirect;
      }
      get referrer() {
        return this[_state].referrer;
      }
      get referrerPolicy() {
        return this[_state].referrerPolicy;
      }
      get signal() {
        return this[_state].signal;
      }
      get url() {
        return this[_state].url;
      }
      // node-fetch properties
      get follow() {
        return this[_state].follow;
      }
      get timeout() {
        return this[_state].timeout;
      }
      get compress() {
        return this[_state].compress;
      }
      get size() {
        return this[_state].size;
      }
      get agent() {
        return this[_state].agent;
      }
      clone() {
        checkBody(this);
        return new _SyncRequest(this.url, this[_state]);
      }
      [util.inspect.custom](depth, options) {
        if (options.depth === null) {
          options.depth = 2;
        }
        options.colors ??= true;
        const properties = {
          ...serializeRequest2(this)[1],
          agent: this.agent,
          signal: this.signal,
          url: this.url
        };
        return `Response ${util.formatWithOptions(options, properties)}`;
      }
    };
    Body.mixin(SyncRequest2.prototype);
    Object.defineProperties(SyncRequest2.prototype, {
      cache: { enumerable: true },
      credentials: { enumerable: true },
      destination: { enumerable: true },
      headers: { enumerable: true },
      integrity: { enumerable: true },
      method: { enumerable: true },
      mode: { enumerable: true },
      priority: { enumerable: true },
      redirect: { enumerable: true },
      referrer: { enumerable: true },
      referrerPolicy: { enumerable: true },
      signal: { enumerable: true },
      url: { enumerable: true },
      clone: { enumerable: true }
    });
    function serializeRequest2(request) {
      return [
        request.url,
        {
          body: request[_state].body ? request[_state].body.toString("base64") : void 0,
          cache: request.cache,
          credentials: request.credentials,
          destination: request.destination,
          headers: Array.from(request.headers),
          integrity: request.integrity,
          keepalive: request.keepalive,
          method: request.method,
          mode: request.mode,
          redirect: request.redirect,
          referrer: request.referrer,
          referrerPolicy: request.referrerPolicy,
          // signal: request.signal,
          // node-fetch props
          follow: request.follow,
          timeout: request.timeout,
          compress: request.compress,
          size: request.size
          // agent: request.agent
        }
      ];
    }
    module2.exports = { SyncRequest: SyncRequest2, serializeRequest: serializeRequest2 };
  }
});

// node_modules/sync-fetch/src/response.js
var require_response = __commonJS({
  "node_modules/sync-fetch/src/response.js"(exports2, module2) {
    var util = require("util");
    var { Body, checkBody, parseBody, createStream, _state } = require_body();
    var { deserializeError: deserializeError2 } = require_error();
    var { SyncHeaders: SyncHeaders2, initializeHeaders } = require_headers();
    var SyncResponse2 = class {
      constructor(body, options = {}) {
        if (typeof options !== "object") {
          throw new TypeError("expected options to be an object");
        }
        const buffer = parseBody(body);
        Object.defineProperty(this, _state, {
          value: {
            status: options.status ?? 200,
            statusText: options.statusText ?? "",
            headers: new SyncHeaders2(options.headers),
            url: "",
            body: buffer,
            bodyStream: body ? createStream(buffer) : null,
            bodyUsed: false
          },
          enumerable: false
        });
        if (body && !this.headers.has("content-type")) {
          const response = new Response(body);
          this.headers.append("content-type", response.headers.get("content-type"));
        }
        if (options.url) {
          this[_state].url = options.url;
        }
      }
      get [Symbol.toStringTag]() {
        return "Response";
      }
      get headers() {
        return this[_state].headers;
      }
      get ok() {
        const status = this[_state].status;
        return status >= 200 && status < 300;
      }
      get redirected() {
        return this[_state].redirected;
      }
      get status() {
        return this[_state].status;
      }
      get statusText() {
        return this[_state].statusText;
      }
      get type() {
        return this[_state].type;
      }
      get url() {
        return this[_state].url;
      }
      clone() {
        checkBody(this);
        return initializeResponse(
          {
            status: this.status,
            statusText: this.statusText,
            headers: new SyncHeaders2(Array.from(this.headers))
          },
          {
            body: Buffer.from(this[_state].body),
            bodyError: this.bodyError,
            redirected: this.redirected,
            type: this.type,
            url: this.url
          }
        );
      }
      [util.inspect.custom](depth, options) {
        if (options.depth === null) {
          options.depth = 2;
        }
        options.colors ??= true;
        const properties = {
          status: this.status,
          statusText: this.statusText,
          headers: this.headers,
          body: this.body,
          bodyUsed: this.bodyUsed,
          ok: this.ok,
          redirected: this.redirected,
          type: this.type,
          url: this.url
        };
        return `Response ${util.formatWithOptions(options, properties)}`;
      }
    };
    Body.mixin(SyncResponse2.prototype);
    Object.defineProperties(SyncResponse2.prototype, {
      headers: { enumerable: true },
      ok: { enumerable: true },
      redirected: { enumerable: true },
      status: { enumerable: true },
      statusText: { enumerable: true },
      type: { enumerable: true },
      url: { enumerable: true },
      clone: { enumerable: true }
    });
    function initializeResponse(init, state) {
      const response = new SyncResponse2(state.body, init);
      response[_state].bodyError = state.bodyError;
      response[_state].redirected = state.redirected;
      response[_state].type = state.type;
      response[_state].url = state.url;
      return response;
    }
    function deserializeResponse2(body, init, bodyError) {
      const options = {
        ...init,
        headers: initializeHeaders(init.headers)
      };
      const state = {
        ...init,
        body: Buffer.from(body, "base64"),
        bodyError: bodyError ? deserializeError2(...bodyError) : void 0
      };
      return initializeResponse(options, state);
    }
    module2.exports = { SyncResponse: SyncResponse2, deserializeResponse: deserializeResponse2 };
  }
});

// node_modules/sync-fetch/index.js
var exec = require("child_process").execFileSync;
var path = require("path");
var { SyncHeaders } = require_headers();
var { FetchError, deserializeError } = require_error();
var { SyncRequest, serializeRequest } = require_request();
var { SyncResponse, deserializeResponse } = require_response();
function syncFetch(resource, init) {
  const request = serializeRequest(new syncFetch.Request(resource, init));
  const [status, ...response] = JSON.parse(sendMessage(request));
  if (status === 0) {
    return deserializeResponse(...response);
  } else {
    throw deserializeError(...response[0]);
  }
}
function sendMessage(message) {
  return exec(process.execPath, [path.join(__dirname, "worker.js")], {
    windowsHide: true,
    maxBuffer: Infinity,
    input: JSON.stringify(message),
    shell: false
  }).toString();
}
syncFetch.Headers = SyncHeaders;
syncFetch.FetchError = FetchError;
syncFetch.Request = SyncRequest;
syncFetch.Response = SyncResponse;
module.exports = syncFetch;
