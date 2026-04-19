/**
 * 세션 관리 JavaScript
 * - 10분 비활성 시 자동 로그아웃
 * - 브라우저 종료 시 세션 해제
 */

class SessionManager {
    constructor() {
        this.TIMEOUT_MINUTES = 10;
        this.TIMEOUT_MS = this.TIMEOUT_MINUTES * 60 * 1000;
        this.warningShown = false;
        this.timeoutId = null;
        this.warningTimeoutId = null;
        
        this.init();
    }
    
    init() {
        // 사용자 활동 감지 이벤트들
        const events = ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart', 'click'];
        
        events.forEach(event => {
            document.addEventListener(event, () => this.resetTimer(), true);
        });
        
        // 브라우저 종료/탭 닫기 시에만 세션 해제 (페이지 이동 제외)
        window.addEventListener('beforeunload', (event) => this.handlePageUnload(event));
        
        // 페이지 가시성 변경 감지 (더 정확한 탭 닫기 감지)
        document.addEventListener('visibilitychange', () => {
            if (document.visibilityState === 'hidden') {
                // 짧은 딜레이 후 여전히 숨겨진 상태면 세션 해제
                setTimeout(() => {
                    if (document.visibilityState === 'hidden') {
                        this.clearSession();
                    }
                }, 1000);
            }
        });
        
        // 초기 타이머 시작
        this.resetTimer();
        
        console.log(`세션 관리자 초기화: ${this.TIMEOUT_MINUTES}분 타임아웃`);
    }
    
    resetTimer() {
        // 기존 타이머 클리어
        if (this.timeoutId) clearTimeout(this.timeoutId);
        if (this.warningTimeoutId) clearTimeout(this.warningTimeoutId);
        
        this.warningShown = false;
        
        // 8분 후 경고 표시 (2분 남음)
        this.warningTimeoutId = setTimeout(() => {
            this.showWarning();
        }, (this.TIMEOUT_MINUTES - 2) * 60 * 1000);
        
        // 10분 후 자동 로그아웃
        this.timeoutId = setTimeout(() => {
            this.autoLogout();
        }, this.TIMEOUT_MS);
    }
    
    showWarning() {
        if (this.warningShown) return;
        this.warningShown = true;
        
        const result = confirm(
            '세션이 2분 후에 만료됩니다.\n' +
            '계속 사용하시겠습니까?\n\n' +
            '확인: 세션 연장\n' +
            '취소: 즉시 로그아웃'
        );
        
        if (result) {
            // 세션 연장을 위해 서버에 요청
            this.extendSession();
        } else {
            // 즉시 로그아웃
            this.logout();
        }
    }
    
    extendSession() {
        fetch('/extend_session', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'same-origin'
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                console.log('세션이 연장되었습니다.');
                this.resetTimer(); // 타이머 재설정
            } else {
                console.log('세션 연장 실패');
                this.logout();
            }
        })
        .catch(error => {
            console.error('세션 연장 오류:', error);
            this.logout();
        });
    }
    
    autoLogout() {
        alert('10분간 활동이 없어 자동으로 로그아웃됩니다.');
        this.logout();
    }
    
    logout() {
        // 로그아웃 요청
        fetch('/logout', {
            method: 'GET',
            credentials: 'same-origin'
        })
        .then(() => {
            window.location.href = '/login';
        })
        .catch(error => {
            console.error('로그아웃 오류:', error);
            window.location.href = '/login';
        });
    }
    
    handlePageUnload(event) {
        // 실제 브라우저 종료/탭 닫기인지 확인
        // 페이지 이동이나 새로고침이 아닌 경우에만 세션 해제
        const isPageNavigation = event && (
            event.target.activeElement && 
            (event.target.activeElement.tagName === 'A' || event.target.activeElement.type === 'submit')
        );
        
        // 페이지 이동이 아닌 경우에만 세션 해제
        if (!isPageNavigation) {
            console.log('브라우저 종료 감지 - 세션 해제');
            if (navigator.sendBeacon) {
                navigator.sendBeacon('/clear_session');
            } else {
                // sendBeacon을 지원하지 않는 경우
                fetch('/clear_session', {
                    method: 'POST',
                    credentials: 'same-origin',
                    keepalive: true
                }).catch(() => {
                    // 에러 무시 (페이지가 이미 언로드된 상태일 수 있음)
                });
            }
        }
    }
    
    clearSession() {
        console.log('세션 해제 요청');
        if (navigator.sendBeacon) {
            navigator.sendBeacon('/clear_session');
        } else {
            fetch('/clear_session', {
                method: 'POST',
                credentials: 'same-origin',
                keepalive: true
            }).catch(() => {
                // 에러 무시
            });
        }
    }
}

// 로그인된 사용자만 세션 관리자 시작
document.addEventListener('DOMContentLoaded', function() {
    // 서버에서 로그인 상태를 전달받아야 함
    if (window.isLoggedIn) {
        new SessionManager();
    }
});