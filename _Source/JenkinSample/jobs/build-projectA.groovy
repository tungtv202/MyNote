multibranchPipelineJob("Sample build") {
    branchSources {
        branchSource {
            source {
                github {
                    id("gatling-project-build")
                    credentialsId('github')
                    repoOwner('tungtv202')
                    repository('gatling-maven-sample')
                    repositoryUrl('')
                    configuredByUrl(false)
                    traits {
                        gitHubTagDiscovery()
                        gitHubBranchDiscovery { strategyId(1) }
                        gitHubPullRequestDiscovery { strategyId(1) }
                    }
                }
            }
            buildStrategies {
                buildAnyBranches {
                    buildChangeRequests {
                        ignoreTargetOnlyChanges(true)
                        ignoreUntrustedChanges(false)
                    }
                    buildNamedBranches {
                        filters {
                            exact {
                                name('master')
                                caseSensitive(true)
                            }
                        }
                    }
                    buildTags {
                        atLeastDays '-1'
                        atMostDays '7'
                    }
                }
            }
        }
    }
    configure {
        // workaround for JENKINS-46202 (https://issues.jenkins-ci.org/browse/JENKINS-46202)
        def traits = it / sources / data / 'jenkins.branch.BranchSource' / source / traits
        traits << 'org.jenkinsci.plugins.github_branch_source.ForkPullRequestDiscoveryTrait' {
            strategyId 1
            trust(class: 'org.jenkinsci.plugins.github_branch_source.ForkPullRequestDiscoveryTrait$TrustPermission')
        }
    }
    triggers {
        periodicFolderTrigger {
            interval('1')
        }
    }
    orphanedItemStrategy {
        defaultOrphanedItemStrategy {
            pruneDeadBranches(true)
            numToKeepStr('')
            daysToKeepStr('')
        } 
    }
}