import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:kubenav/controllers/cluster_controller.dart';
import 'package:kubenav/models/provider_config_model.dart';
import 'package:kubenav/models/provider_model.dart';
import 'package:kubenav/services/azure_service.dart';
import 'package:kubenav/utils/constants.dart';
import 'package:kubenav/utils/helpers.dart';
import 'package:kubenav/utils/logger.dart';
import 'package:kubenav/widgets/app_bottom_sheet_widget.dart';
import 'package:kubenav/widgets/app_error_widget.dart';

class AddClusterAzureController extends GetxController {
  ClusterController clusterController = Get.find();
  final ProviderConfig providerConfig;
  RxString error = ''.obs;
  RxBool loading = false.obs;
  RxList<AzureCluster> clusters = <AzureCluster>[].obs;
  RxList<AzureCluster> selectedClusters = <AzureCluster>[].obs;

  AddClusterAzureController({
    required this.providerConfig,
  });

  @override
  void onInit() {
    getClusters();
    super.onInit();
  }

  void getClusters() async {
    loading.value = true;

    try {
      if (providerConfig.azure != null) {
        final tmpClusters = await AzureService().getClusters(
          providerConfig.azure!.subscriptionID,
          providerConfig.azure!.tenantID,
          providerConfig.azure!.clientID,
          providerConfig.azure!.clientSecret,
          providerConfig.azure!.isAdmin,
        );

        Logger.log(
          'AddClusterAzureController getClusters',
          'Clusters were returned',
          tmpClusters,
        );
        clusters.value = tmpClusters;
      } else {
        error.value = 'Provider configuration is invalid';
      }
    } catch (err) {
      Logger.log(
        'AddClusterAzureController getClusters',
        'Could not get clusters',
        err,
      );
      error.value = err.toString();
    }

    loading.value = false;
  }

  void addClusters() {
    for (var selectedCluster in selectedClusters) {
      if (selectedCluster.name != null && selectedCluster.kubeconfig != null) {
        final tmpClusters = selectedCluster.kubeconfig!
            .getClusters('azure', providerConfig.name);
        for (var tmpCluster in tmpClusters) {
          tmpCluster.name = selectedCluster.name!;
          final addClusterError = clusterController.addCluster(tmpCluster);
          if (addClusterError != null) {
            snackbar(
              'Could not add cluster ${tmpCluster.name}',
              addClusterError,
            );
          }
        }
      }
    }
  }
}

class AddClusterAzureWidget extends StatelessWidget {
  const AddClusterAzureWidget({
    Key? key,
    required this.providerConfig,
  }) : super(key: key);

  final ProviderConfig providerConfig;

  @override
  Widget build(BuildContext context) {
    AddClusterAzureController controller = Get.put(
      AddClusterAzureController(providerConfig: providerConfig),
    );

    return AppBottomSheetWidget(
      title: Providers.azure.title,
      subtitle: Providers.azure.subtitle,
      icon: Providers.azure.image54x54,
      onClosePressed: () {
        finish(context);
      },
      actionText: 'Add Clusters',
      onActionPressed: () {
        controller.addClusters();
        finish(context);
      },
      child: Obx(
        () {
          if (controller.loading.value) {
            return Flex(
              direction: Axis.vertical,
              children: [
                Expanded(
                  child: Wrap(
                    children: const [
                      CircularProgressIndicator(color: Constants.colorPrimary),
                    ],
                  ),
                ),
              ],
            );
          }

          if (controller.error.value != '') {
            return Flex(
              direction: Axis.vertical,
              children: [
                Expanded(
                  child: Wrap(
                    children: [
                      AppErrorWidget(
                        message: 'Could not load clusters',
                        details: controller.error.value,
                        icon: Providers.azure.image250x140,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView(
            children: [
              ...List.generate(
                controller.clusters.length,
                (index) {
                  return Container(
                    margin: const EdgeInsets.only(
                      top: Constants.spacingSmall,
                      bottom: Constants.spacingSmall,
                      left: Constants.spacingExtraSmall,
                      right: Constants.spacingExtraSmall,
                    ),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor,
                          blurRadius: Constants.sizeBorderBlurRadius,
                          spreadRadius: Constants.sizeBorderSpreadRadius,
                          offset: const Offset(0.0, 0.0),
                        ),
                      ],
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(Constants.sizeBorderRadius),
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          checkColor: Colors.white,
                          fillColor: MaterialStateProperty.all(
                            Constants.colorPrimary,
                          ),
                          value: controller.selectedClusters
                                  .where((c) =>
                                      c.name == controller.clusters[index].name)
                                  .toList()
                                  .length ==
                              1,
                          onChanged: (bool? value) {
                            if (value == true) {
                              controller.selectedClusters
                                  .add(controller.clusters[index]);
                            }
                            if (value == false) {
                              controller.selectedClusters.value = controller
                                  .selectedClusters
                                  .where((c) =>
                                      c.name != controller.clusters[index].name)
                                  .toList();
                            }
                          },
                        ),
                        const SizedBox(width: Constants.spacingSmall),
                        Expanded(
                          flex: 1,
                          child: Text(
                            controller.clusters[index].name ?? '',
                            style: noramlTextStyle(
                              context,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}