package dev.rgal.brackety.grouping.dto;

/** A mat put out of use: how many groups went to other mats and how many team matches went back to the pool. */
public record DisabledMat(int groupsMoved, int teamMatchesToPool) {}
