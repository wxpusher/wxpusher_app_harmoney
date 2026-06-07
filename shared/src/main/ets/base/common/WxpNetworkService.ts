import { http } from '@kit.NetworkKit';
import { WxpConfig } from '../../config/WxpConfig';
import { WxpBaseInfoService } from './WxpBaseInfoService';
import { WxpLogUtils } from './WxpLogUtils';

/**
 * 对应 KMP WxpNetworkService.kt + BaseResp
 */
export interface BaseResp<T> {
  code: number;
  msg: string;
  data: T;
}

// 登录信息获取器，避免循环依赖
let loginInfoGetter: (() => string) | null = null;

export class WxpNetworkService {
  private static readonly TAG = 'WxpNetwork';

  static setLoginInfoGetter(getter: () => string): void {
    loginInfoGetter = getter;
  }

  static getUrl(path: string): string {
    const base = WxpConfig.baseUrl.endsWith('/') ?
      WxpConfig.baseUrl.slice(0, -1) : WxpConfig.baseUrl;
    return `${base}${path}`;
  }

  private static getDefaultHeaders(): Record<string, string> {
    return {
      'Content-Type': 'application/json',
      'deviceToken': loginInfoGetter ? loginInfoGetter() : '',
      'version': WxpBaseInfoService.getAppVersionName(),
      'platform': WxpBaseInfoService.getPlatform(),
    };
  }

  static async get<T>(url: string, params?: Record<string, string>): Promise<BaseResp<T>> {
    let fullUrl = url;
    if (params) {
      const query = Object.entries(params)
        .filter(([_, v]) => v !== null && v !== undefined)
        .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
        .join('&');
      if (query.length > 0) {
        fullUrl += (url.includes('?') ? '&' : '?') + query;
      }
    }
    WxpLogUtils.d(WxpNetworkService.TAG, `GET ${fullUrl}`);
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.GET,
        header: WxpNetworkService.getDefaultHeaders(),
        expectDataType: http.HttpDataType.STRING,
      });
      return JSON.parse(response.result as string) as BaseResp<T>;
    } finally {
      httpRequest.destroy();
    }
  }

  static async post<T>(url: string, body?: Object): Promise<BaseResp<T>> {
    WxpLogUtils.d(WxpNetworkService.TAG, `POST ${url}`);
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: WxpNetworkService.getDefaultHeaders(),
        extraData: body ? JSON.stringify(body) : undefined,
        expectDataType: http.HttpDataType.STRING,
      });
      WxpLogUtils.d(WxpNetworkService.TAG, `resp ${response.result}`);
      return JSON.parse(response.result as string) as BaseResp<T>;
    } finally {
      httpRequest.destroy();
    }
  }

  static async put<T>(url: string, body?: Object): Promise<BaseResp<T>> {
    WxpLogUtils.d(WxpNetworkService.TAG, `PUT ${url}`);
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.PUT,
        header: WxpNetworkService.getDefaultHeaders(),
        extraData: body ? JSON.stringify(body) : undefined,
        expectDataType: http.HttpDataType.STRING,
      });
      return JSON.parse(response.result as string) as BaseResp<T>;
    } finally {
      httpRequest.destroy();
    }
  }

  static async delete<T>(url: string, params?: Record<string, string>): Promise<BaseResp<T>> {
    let fullUrl = url;
    if (params) {
      const query = Object.entries(params)
        .filter(([_, v]) => v !== null && v !== undefined)
        .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
        .join('&');
      if (query.length > 0) {
        fullUrl += (url.includes('?') ? '&' : '?') + query;
      }
    }
    WxpLogUtils.d(WxpNetworkService.TAG, `DELETE ${fullUrl}`);
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.DELETE,
        header: WxpNetworkService.getDefaultHeaders(),
        expectDataType: http.HttpDataType.STRING,
      });
      return JSON.parse(response.result as string) as BaseResp<T>;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 简单的 GET 请求，返回文本
   */
  static async getText(url: string, extraHeaders?: Record<string, string>): Promise<string> {
    const httpRequest = http.createHttp();
    try {
      const headers: Record<string, string> = { ...WxpNetworkService.getDefaultHeaders(), ...extraHeaders };
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: headers,
        expectDataType: http.HttpDataType.STRING,
      });
      return response.result as string;
    } finally {
      httpRequest.destroy();
    }
  }
}
