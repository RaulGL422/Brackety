package dev.rgal.brackety.auth.dto;

public record RefreshRequest(String refreshToken) {

    @Override
    public String toString() {
        return "RefreshRequest[]";
    }
}
